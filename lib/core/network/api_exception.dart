import 'dart:async';

import 'package:dio/dio.dart';

import '../logger/app_logger.dart';

/// One field of a VALIDATION_ERROR (`details[]`): [field] is the JSON path in
/// the request (`name`, `splits[0].amount`), [code] one of required /
/// too_long / too_short / too_many / too_few / out_of_range / invalid /
/// invalid_type / invalid_json / too_large.
class ApiFieldError {
  const ApiFieldError({
    required this.field,
    required this.code,
    this.params = const {},
  });

  final String field;
  final String code;
  final Map<String, dynamic> params;

  static List<ApiFieldError> listFrom(Object? details) => [
    if (details is List)
      for (final d in details)
        if (d is Map && d['field'] is String && d['code'] is String)
          ApiFieldError(
            field: d['field'] as String,
            code: d['code'] as String,
            params: d['params'] is Map
                ? Map<String, dynamic>.from(d['params'] as Map)
                : const {},
          ),
  ];
}

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
    this.fields = const [],
    this.requestId,
  });

  final String code;

  final String message;

  final int? statusCode;

  final Map<String, dynamic>? details;

  /// The fields a VALIDATION_ERROR names (its `details` list).
  final List<ApiFieldError> fields;

  final String? requestId;

  /// The error of one field (exact path), null when it has none.
  ApiFieldError? fieldError(String field) {
    for (final f in fields) {
      if (f.field == field) return f;
    }
    return null;
  }

  factory ApiException.fromDioException(DioException e) {
    final response = e.response;
    final data = response?.data;
    final reqId = _extractRequestId(e);

    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        code: (err['code'] as String?) ?? 'UNKNOWN_ERROR',
        message: (err['message'] as String?) ?? e.message ?? 'Unknown error',
        statusCode: response?.statusCode,
        details: err['details'] is Map
            ? Map<String, dynamic>.from(err['details'] as Map)
            : null,
        fields: ApiFieldError.listFrom(err['details']),
        requestId: reqId,
      );
    }

    final code = switch (e.type) {
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'NETWORK_TIMEOUT',
      DioExceptionType.cancel => 'REQUEST_CANCELLED',
      _ when isNetworkFailure(e) => 'NETWORK_ERROR',
      _ when _serverDown.contains(response?.statusCode) => 'SERVER_UNAVAILABLE',
      _ => 'UNKNOWN_ERROR',
    };

    return ApiException(
      code: code,
      message: e.message ?? 'Network error',
      statusCode: response?.statusCode,
      requestId: reqId,
    );
  }

  factory ApiException.from(Object error, [StackTrace? stack]) {
    if (error is ApiException) return error;
    AppLogger.instance.error(
      'unexpected_error',
      fields: {
        'error': error.toString(),
        if (stack != null) 'stack': stack.toString(),
      },
    );
    return ApiException(code: 'UNEXPECTED_ERROR', message: error.toString());
  }

  /// THE network classifier: the request never got an answer (no route,
  /// timeout, a socket error wrapped as unknown). A response of any status is
  /// not a network failure.
  static bool isNetworkFailure(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      (e.type == DioExceptionType.unknown && e.error is! FormatException);

  /// The proxy answered for a BE that is down or restarting.
  static const _serverDown = {502, 503, 504};

  /// This exception is a network failure (see [isNetworkFailure]).
  bool get isNetwork => code == 'NETWORK_ERROR' || code == 'NETWORK_TIMEOUT';

  static String? _extractRequestId(DioException e) {
    final fromResponse = e.response?.headers.value('x-request-id');
    if (fromResponse != null && fromResponse.isNotEmpty) return fromResponse;
    final fromRequest = e.requestOptions.headers['X-Request-ID'];
    if (fromRequest is String && fromRequest.isNotEmpty) return fromRequest;
    return null;
  }

  @override
  String toString() =>
      'ApiException($code: $message${requestId != null ? " req=$requestId" : ""})';
}

/// Any thrown value that means 'could not reach the server': an
/// [ApiException] built from a network failure, or a client-side timeout.
bool isNetworkError(Object error) =>
    error is TimeoutException || (error is ApiException && error.isNetwork);

/// A network failure where the server was reached but answered too late
/// (a client-side timeout too); the rest of [isNetworkError] is "offline".
/// The kit's offline page view throws `TimeoutException('offline')`.
bool isSlowNetworkError(Object error) =>
    (error is TimeoutException && error.message != 'offline') ||
    (error is ApiException && error.code == 'NETWORK_TIMEOUT');
