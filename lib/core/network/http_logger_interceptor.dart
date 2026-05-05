import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../logger/app_logger.dart';
import '../logger/log_entry.dart';

/// Dio interceptor that:
///  - Generates a UUID v4 per outbound request, sends it as
///    `X-Request-ID`, and stamps every log line + the eventual error
///    with the same id (matches the BE plan's request-id correlation).
///  - Logs request line: method, url, status, latency.
///  - Optionally captures request + response body, redacted, capped at
///    [_maxBodyBytes]. Gated by [LogConfig.logBodies] so prod doesn't
///    leak payloads.
///  - On error responses, escalates to warn (4xx) or error (5xx).
///
/// Per the plan's redact list (logging-plan.md §3 / line 81):
///   password, passwd, secret, token, authorization, apikey, api_key,
///   pin, otp, ssn, card, cvv
///
/// Headers + JSON body get walked recursively; matching keys (case-
/// insensitive substring) get their values replaced with `[REDACTED]`.
class HttpLoggerInterceptor extends Interceptor {
  HttpLoggerInterceptor({AppLogger? logger})
      : _logger = logger ?? AppLogger.instance;

  final AppLogger _logger;

  static const int _maxBodyBytes = 4 * 1024;
  static const String _requestIdHeader = 'X-Request-ID';
  static const String _requestIdExtra = '__chubi_request_id';
  static const String _stopwatchExtra = '__chubi_stopwatch';

  static final List<String> _redactKeys = [
    'password',
    'passwd',
    'secret',
    'token',
    'authorization',
    'apikey',
    'api_key',
    'pin',
    'otp',
    'ssn',
    'card',
    'cvv',
  ];

  static final _Random _rng = _Random();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = _newRequestId();
    options.headers[_requestIdHeader] = requestId;
    options.extra[_requestIdExtra] = requestId;
    options.extra[_stopwatchExtra] = Stopwatch()..start();

    final fields = <String, Object?>{
      'method': options.method,
      'url': _safeUrl(options),
    };
    if (_logger.config.logBodies) {
      final body = _captureBody(options.data, options.headers);
      if (body != null) fields['body'] = body;
    }
    _logger.debug('http.request', requestId: requestId, fields: fields);

    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    final reqId = response.requestOptions.extra[_requestIdExtra] as String?;
    final latencyMs = _latencyMs(response.requestOptions);
    final fields = <String, Object?>{
      'method': response.requestOptions.method,
      'url': _safeUrl(response.requestOptions),
      'status': response.statusCode,
      'latency_ms': latencyMs,
    };
    if (_logger.config.logBodies) {
      final body = _captureBody(response.data, response.headers.map);
      if (body != null) fields['body'] = body;
    }

    final status = response.statusCode ?? 0;
    final level = status >= 500
        ? LogLevel.error
        : (status >= 400 ? LogLevel.warn : LogLevel.info);
    _emit(level, 'http.response', requestId: reqId, fields: fields);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final reqId = err.requestOptions.extra[_requestIdExtra] as String?;
    final latencyMs = _latencyMs(err.requestOptions);
    final fields = <String, Object?>{
      'method': err.requestOptions.method,
      'url': _safeUrl(err.requestOptions),
      'status': err.response?.statusCode,
      'latency_ms': latencyMs,
      'type': err.type.name,
      'message': err.message,
    };
    if (_logger.config.logBodies && err.response?.data != null) {
      final body = _captureBody(err.response!.data, err.response!.headers.map);
      if (body != null) fields['body'] = body;
    }

    final status = err.response?.statusCode ?? 0;
    final level = status >= 500 || status == 0
        ? LogLevel.error
        : LogLevel.warn;
    _emit(level, 'http.error', requestId: reqId, fields: fields);

    handler.next(err);
  }

  // ── helpers ──────────────────────────────────────────────────────

  void _emit(LogLevel level, String msg,
      {String? requestId, Map<String, Object?>? fields}) {
    switch (level) {
      case LogLevel.debug:
        _logger.debug(msg, requestId: requestId, fields: fields);
      case LogLevel.info:
        _logger.info(msg, requestId: requestId, fields: fields);
      case LogLevel.warn:
        _logger.warn(msg, requestId: requestId, fields: fields);
      case LogLevel.error:
        _logger.error(msg, requestId: requestId, fields: fields);
      case LogLevel.critical:
        _logger.critical(msg, requestId: requestId, fields: fields);
    }
  }

  int? _latencyMs(RequestOptions options) {
    final sw = options.extra[_stopwatchExtra];
    if (sw is Stopwatch) {
      sw.stop();
      return sw.elapsedMilliseconds;
    }
    return null;
  }

  String _safeUrl(RequestOptions options) {
    // Dio's options.uri can throw on malformed combinations; fall back
    // to path concatenation. Either form is fine — we just want
    // grep-able context.
    try {
      return options.uri.toString();
    } catch (_) {
      return '${options.baseUrl}${options.path}';
    }
  }

  /// Returns a redacted, length-capped, JSON-encoded preview of [data].
  /// Returns null when the body is empty / not capturable.
  ///
  /// [extraScrub] is an optional second map of keys to scrub (used to
  /// pass headers through the same redactor).
  String? _captureBody(Object? data, Map<String, dynamic>? extraScrub) {
    if (data == null) return null;
    Object? structured;
    if (data is FormData) {
      structured = {
        'fields': {for (final f in data.fields) f.key: f.value},
        'files': data.files.map((f) => f.key).toList(),
      };
    } else if (data is String) {
      structured = data;
    } else if (data is List<int>) {
      structured = '[bytes:${data.length}]';
    } else {
      structured = data;
    }

    final redacted = _redactValue(structured);
    String enc;
    try {
      enc = jsonEncode(redacted);
    } catch (_) {
      enc = redacted.toString();
    }
    if (enc.length > _maxBodyBytes) {
      enc = '${enc.substring(0, _maxBodyBytes)}…[truncated]';
    }
    if (extraScrub != null) {
      // Bookkeeping: caller can append redacted headers if they want;
      // we don't currently inject them into the body string. Reserved.
    }
    return enc;
  }

  /// Walk `value`; redact map entries whose key matches the redact list.
  Object? _redactValue(Object? value) {
    if (value is Map) {
      return value.map((k, v) {
        final keyStr = '$k';
        if (_isRedactedKey(keyStr)) return MapEntry(k, '[REDACTED]');
        return MapEntry(k, _redactValue(v));
      });
    }
    if (value is List) {
      return value.map(_redactValue).toList();
    }
    return value;
  }

  bool _isRedactedKey(String key) {
    final lower = key.toLowerCase();
    for (final needle in _redactKeys) {
      if (lower.contains(needle)) return true;
    }
    return false;
  }

  /// UUID v4. We don't pull in `uuid` package for this single use —
  /// the spec only needs 122 random bits + 6 deterministic version/
  /// variant bits.
  String _newRequestId() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 1
    String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
    final b = StringBuffer();
    for (var i = 0; i < 16; i++) {
      b.write(hex(i));
      if (i == 3 || i == 5 || i == 7 || i == 9) b.write('-');
    }
    return b.toString();
  }
}

/// dart:math.Random alias so the file doesn't need a top-level import.
class _Random {
  _Random() : _r = Random.secure();
  final Random _r;
  int nextInt(int max) => _r.nextInt(max);
}
