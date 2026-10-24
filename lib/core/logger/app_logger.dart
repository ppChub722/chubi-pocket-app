import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'breadcrumbs.dart';
import 'log_config.dart';
import 'log_entry.dart';

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const int _ringCapacity = 1000;
  static const int _maxFileBytes = 1024 * 1024; // 1 MiB
  static const int _maxFiles = 3; // app.log + .1 + .2

  LogConfig _config = const LogConfig(
    env: AppEnv.local,
    minLevel: LogLevel.debug,
    logBodies: true,
    fileSink: true,
  );

  LogConfig get config => _config;

  final List<LogEntry> _ring = [];
  final StreamController<LogEntry> _stream =
      StreamController<LogEntry>.broadcast();

  Stream<LogEntry> get onEntry => _stream.stream;

  List<LogEntry> get recent => List.unmodifiable(_ring);

  String? _currentUserId;

  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  bool _initialised = false;
  File? _file;
  int _bytes = 0;
  Future<void> _pending = Future.value();

  Future<void> init([LogConfig? config]) async {
    if (_initialised) return;
    _initialised = true;
    _config = config ?? LogConfig.fromEnv();
    if (kIsWeb || !_config.fileSink) {
      info(
        'logger.init',
        fields: {'sink': 'memory-only', 'config': _config.toString()},
      );
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
      info(
        'logger.init',
        fields: {
          'sink': 'file',
          'path': f.path,
          'bytes': _bytes,
          'config': _config.toString(),
        },
      );
    } catch (e, st) {
      _file = null;
      debugPrint('AppLogger.init failed: $e\n$st');
    }
  }

  String? get filePath => _file?.path;

  Future<String> readAllForShare() async {
    final f = _file;
    if (f == null) return _ring.map((e) => e.toJsonLine()).join('\n');
    final dir = f.parent;
    final files = <File>[];
    for (var i = _maxFiles - 1; i >= 0; i--) {
      final candidate = File(
        i == 0 ? '${dir.path}/app.log' : '${dir.path}/app.log.$i',
      );
      if (candidate.existsSync()) files.add(candidate);
    }
    final buf = StringBuffer();
    for (final cf in files) {
      buf.write(await cf.readAsString());
    }
    return buf.toString();
  }

  void debug(String msg, {Map<String, Object?>? fields, String? requestId}) =>
      _emit(LogLevel.debug, msg, fields, requestId, _currentUserId);

  void info(String msg, {Map<String, Object?>? fields, String? requestId}) =>
      _emit(LogLevel.info, msg, fields, requestId, _currentUserId);

  void warn(String msg, {Map<String, Object?>? fields, String? requestId}) =>
      _emit(LogLevel.warn, msg, fields, requestId, _currentUserId);

  void error(
    String msg, {
    Map<String, Object?>? fields,
    String? requestId,
    String? userId,
  }) => _emit(LogLevel.error, msg, fields, requestId, userId ?? _currentUserId);

  void critical(
    String msg, {
    Map<String, Object?>? fields,
    String? requestId,
    String? userId,
  }) => _emit(
    LogLevel.critical,
    msg,
    fields,
    requestId,
    userId ?? _currentUserId,
  );

  void _emit(
    LogLevel level,
    String msg,
    Map<String, Object?>? fields,
    String? requestId,
    String? userId,
  ) {
    if (level.severity < _config.minLevel.severity) return;

    // An error carries the steps that led to it (Breadcrumbs).
    final withSteps =
        level.severity >= LogLevel.error.severity &&
            Breadcrumbs.instance.steps.isNotEmpty &&
            !(fields?.containsKey('steps') ?? false)
        ? {...?fields, 'steps': Breadcrumbs.instance.steps}
        : fields;
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: msg,
      requestId: requestId,
      userId: userId,
      fields: withSteps ?? const {},
    );

    _ring.add(entry);
    while (_ring.length > _ringCapacity) {
      _ring.removeAt(0);
    }
    if (!_stream.isClosed) _stream.add(entry);

    if (kDebugMode) {
      debugPrint(entry.toHumanLine());
    }

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
      // Drop the line on the floor — we don't want a logger to break the app.
    }
  }

  Future<void> _rotate(File current) async {
    try {
      final dir = current.parent;
      for (var i = _maxFiles - 1; i >= 1; i--) {
        final src = File(
          i == 1 ? '${dir.path}/app.log' : '${dir.path}/app.log.${i - 1}',
        );
        final dst = File('${dir.path}/app.log.$i');
        if (src.existsSync()) {
          if (dst.existsSync()) await dst.delete();
          await src.rename(dst.path);
        }
      }
      await current.writeAsString('', mode: FileMode.write);
      _bytes = 0;
    } catch (_) {}
  }
}
