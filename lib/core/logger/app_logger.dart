import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'log_config.dart';
import 'log_entry.dart';

/// Process-wide logger. Singleton; init once during app start
/// (`main.dart` before `runApp`).
///
/// Two sinks:
///  1. **In-memory ring buffer** — last [_ringCapacity] entries, always
///     on. Backs the `/dev/logs` viewer + the share-recent action.
///  2. **File sink** — NDJSON appended to
///     `getApplicationDocumentsDirectory()/chubi_logs/app.log`. Rotated
///     when the active file exceeds [_maxFileBytes]; keeps the last
///     [_maxFiles] including the live one. Disabled silently on web /
///     where path_provider isn't available.
///
/// Log writes are non-blocking from the caller's perspective. The file
/// sink serialises through a single [Future] chain to avoid interleaved
/// writes; if it falls behind the ring buffer is the source of truth
/// for debugging.
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  // ── tunables ─────────────────────────────────────────────────────
  static const int _ringCapacity = 1000;
  static const int _maxFileBytes = 1024 * 1024; // 1 MiB
  static const int _maxFiles = 3; // app.log + .1 + .2

  // ── config (resolved on init) ────────────────────────────────────
  LogConfig _config = const LogConfig(
    env: AppEnv.local,
    minLevel: LogLevel.debug,
    logBodies: true,
    fileSink: true,
  );

  /// Active config. Read by [HttpLoggerInterceptor] to gate body capture
  /// and by anyone who needs to know the env / current min level.
  LogConfig get config => _config;

  // ── in-memory ring ───────────────────────────────────────────────
  final List<LogEntry> _ring = [];
  final StreamController<LogEntry> _stream =
      StreamController<LogEntry>.broadcast();

  /// Hot stream of new entries. Closes only when the process exits.
  Stream<LogEntry> get onEntry => _stream.stream;

  /// Snapshot of the ring buffer (newest last). Cheap to call — just
  /// returns an unmodifiable view. The dev page sorts/filters from here.
  List<LogEntry> get recent => List.unmodifiable(_ring);

  // ── default request/user context ──────────────────────────────────
  String? _currentUserId;

  /// Set by AuthCubit when login lands; cleared on logout. Every entry
  /// after this picks it up automatically unless the caller passes an
  /// explicit `userId:` override (used by login_failed log lines, where
  /// auth is mid-flight).
  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  // ── file sink state ──────────────────────────────────────────────
  bool _initialised = false;
  File? _file;
  int _bytes = 0;
  Future<void> _pending = Future.value();

  // ── lifecycle ────────────────────────────────────────────────────

  /// Set up the file sink + freeze the active config. Safe to call
  /// repeatedly — second call is a no-op (the first config wins).
  /// Failures (e.g. on web, sandboxed file system) are swallowed; the
  /// logger falls back to in-memory + console only.
  Future<void> init([LogConfig? config]) async {
    if (_initialised) return;
    _initialised = true;
    _config = config ?? LogConfig.fromEnv();
    if (kIsWeb || !_config.fileSink) {
      info('logger.init',
          fields: {'sink': 'memory-only', 'config': _config.toString()});
      return;
    }
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/chubi_logs');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final f = File('${dir.path}/app.log');
      if (!f.existsSync()) f.createSync();
      _file = f;
      _bytes = await f.length();
      info('logger.init', fields: {
        'sink': 'file',
        'path': f.path,
        'bytes': _bytes,
        'config': _config.toString(),
      });
    } catch (e, st) {
      // swallow — disable file sink, keep ring buffer
      _file = null;
      debugPrint('AppLogger.init failed: $e\n$st');
    }
  }

  /// Path of the active log file, or null when the file sink is off
  /// (web / init failure). Used by the dev viewer to show + share.
  String? get filePath => _file?.path;

  /// Returns the contents of all log files (current + rotated) joined.
  /// Used by the "share log" action. Reads on every call — no caching.
  Future<String> readAllForShare() async {
    final f = _file;
    if (f == null) return _ring.map((e) => e.toJsonLine()).join('\n');
    final dir = f.parent;
    final files = <File>[];
    for (var i = _maxFiles - 1; i >= 0; i--) {
      final candidate =
          File(i == 0 ? '${dir.path}/app.log' : '${dir.path}/app.log.$i');
      if (candidate.existsSync()) files.add(candidate);
    }
    final buf = StringBuffer();
    for (final cf in files) {
      buf.write(await cf.readAsString());
    }
    return buf.toString();
  }

  // ── public log methods ───────────────────────────────────────────

  void debug(String msg, {Map<String, Object?>? fields, String? requestId}) =>
      _emit(LogLevel.debug, msg, fields, requestId, _currentUserId);

  void info(String msg, {Map<String, Object?>? fields, String? requestId}) =>
      _emit(LogLevel.info, msg, fields, requestId, _currentUserId);

  void warn(String msg, {Map<String, Object?>? fields, String? requestId}) =>
      _emit(LogLevel.warn, msg, fields, requestId, _currentUserId);

  void error(String msg,
          {Map<String, Object?>? fields,
          String? requestId,
          String? userId}) =>
      _emit(LogLevel.error, msg, fields, requestId,
          userId ?? _currentUserId);

  void critical(String msg,
          {Map<String, Object?>? fields,
          String? requestId,
          String? userId}) =>
      _emit(LogLevel.critical, msg, fields, requestId,
          userId ?? _currentUserId);

  // ── internals ────────────────────────────────────────────────────

  void _emit(LogLevel level, String msg, Map<String, Object?>? fields,
      String? requestId, String? userId) {
    // Drop sub-threshold entries entirely — neither ring nor file sees
    // them. This is the hot path; cheap integer compare.
    if (level.severity < _config.minLevel.severity) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: msg,
      requestId: requestId,
      userId: userId,
      fields: fields ?? const {},
    );

    // Ring
    _ring.add(entry);
    while (_ring.length > _ringCapacity) {
      _ring.removeAt(0);
    }
    if (!_stream.isClosed) _stream.add(entry);

    // Stdout — useful in `flutter logs` during dev. Off in release.
    if (kDebugMode) {
      debugPrint(entry.toHumanLine());
    }

    // File (best-effort, serialised)
    final f = _file;
    if (f != null) {
      _pending = _pending.then((_) => _writeLine(f, entry));
    }
  }

  Future<void> _writeLine(File f, LogEntry entry) async {
    try {
      final line = '${entry.toJsonLine()}\n';
      await f.writeAsString(line, mode: FileMode.append, flush: false);
      _bytes += line.length;
      if (_bytes >= _maxFileBytes) {
        await _rotate(f);
      }
    } catch (_) {
      // Drop the line on the floor — we don't want a logger to break
      // the app. The ring buffer still has it.
    }
  }

  Future<void> _rotate(File current) async {
    try {
      final dir = current.parent;
      // Shift app.log.(N-2) → .(N-1), .1 → .2, app.log → .1
      for (var i = _maxFiles - 1; i >= 1; i--) {
        final src = File(
            i == 1 ? '${dir.path}/app.log' : '${dir.path}/app.log.${i - 1}');
        final dst = File('${dir.path}/app.log.$i');
        if (src.existsSync()) {
          if (dst.existsSync()) await dst.delete();
          await src.rename(dst.path);
        }
      }
      // Re-create app.log empty.
      await current.writeAsString('', mode: FileMode.write);
      _bytes = 0;
    } catch (_) {
      // If rotation fails, we just keep appending to the (over-sized)
      // current file. Worst case: one log file gets bigger than
      // expected. Better than crashing the app on a logger.
    }
  }
}
