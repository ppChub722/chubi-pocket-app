import 'dart:async';

import 'package:dio/dio.dart';

import '../logger/app_logger.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
    this.requestId,
  });

  final String code;

  final String message;

  final int? statusCode;

  final Map<String, dynamic>? details;

  final String? requestId;

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
        requestId: reqId,
      );
    }

    final code = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'NETWORK_TIMEOUT',
      DioExceptionType.connectionError => 'NETWORK_ERROR',
      DioExceptionType.cancel => 'REQUEST_CANCELLED',
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
