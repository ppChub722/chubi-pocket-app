import 'dart:convert';

/// One log line. Immutable, JSON-serialisable.
///
/// Format follows the BE plan loosely (`engineering/logging-plan.md`):
/// timestamp first, level next, then a short human message + a flat
/// fields map for structured detail. Request id and user id are first-
/// class because the BE log line carries them too — same key lets you
/// grep across stacks.
enum LogLevel {
  debug,
  info,
  warn,
  error,
  critical;

  /// Single-character tag used in the human-readable view. Compact so
  /// long lines don't wrap on a phone screen.
  String get tag => switch (this) {
        LogLevel.debug => 'D',
        LogLevel.info => 'I',
        LogLevel.warn => 'W',
        LogLevel.error => 'E',
        LogLevel.critical => 'C',
      };

  /// Wire string for JSON sink — matches slog level names so a
  /// log-aggregator can colourize FE + BE lines uniformly.
  String get wire => name.toUpperCase();

  /// Numeric severity for filtering. Higher = more severe.
  int get severity => switch (this) {
        LogLevel.debug => 0,
        LogLevel.info => 1,
        LogLevel.warn => 2,
        LogLevel.error => 3,
        LogLevel.critical => 4,
      };

  static LogLevel? parse(String? raw) {
    if (raw == null) return null;
    final v = raw.toUpperCase();
    for (final l in LogLevel.values) {
      if (l.wire == v) return l;
    }
    return null;
  }
}

class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.requestId,
    this.userId,
    this.fields = const {},
  });

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? requestId;
  final String? userId;
  final Map<String, Object?> fields;

  /// NDJSON-style line — one entry per JSON object. Trailing newline NOT
  /// included; the file sink adds it.
  String toJsonLine() => jsonEncode(<String, Object?>{
        'ts': timestamp.toUtc().toIso8601String(),
        'level': level.wire,
        'msg': message,
        if (requestId != null) 'request_id': requestId,
        if (userId != null) 'user_id': userId,
        if (fields.isNotEmpty) 'fields': fields,
      });

  /// Parse one NDJSON line back into a [LogEntry]. Used by the dev
  /// viewer page when re-reading the file. Returns null on malformed
  /// input rather than throwing — the viewer just skips bad lines.
  static LogEntry? tryParseJson(String line) {
    try {
      final raw = jsonDecode(line);
      if (raw is! Map<String, dynamic>) return null;
      final ts = DateTime.tryParse(raw['ts'] as String? ?? '');
      final level = LogLevel.parse(raw['level'] as String?);
      final msg = raw['msg'] as String?;
      if (ts == null || level == null || msg == null) return null;
      final fieldsRaw = raw['fields'];
      return LogEntry(
        timestamp: ts,
        level: level,
        message: msg,
        requestId: raw['request_id'] as String?,
        userId: raw['user_id'] as String?,
        fields: fieldsRaw is Map<String, Object?>
            ? Map.unmodifiable(fieldsRaw)
            : const {},
      );
    } catch (_) {
      return null;
    }
  }

  /// Pretty single-line form used in the dev viewer. Format:
  ///   `HH:mm:ss.SSS [I] message  {req=abc user=xyz} key=val`
  String toHumanLine() {
    final t = timestamp.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    final time =
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${three(t.millisecond)}';
    final tag = '[${level.tag}]';
    final ctx = <String>[
      if (requestId != null) 'req=${_short(requestId!)}',
      if (userId != null) 'user=${_short(userId!)}',
    ];
    final ctxStr = ctx.isEmpty ? '' : '  {${ctx.join(' ')}}';
    final fStr = fields.isEmpty
        ? ''
        : '  ${fields.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    return '$time $tag $message$ctxStr$fStr';
  }

  static String _short(String s) => s.length > 8 ? s.substring(0, 8) : s;
}
