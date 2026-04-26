import 'package:dio/dio.dart';

/// Typed error raised by repositories after a failed API call.
///
/// Thrown by Repository methods (which catch [DioException] and convert via
/// [ApiException.fromDioException]). UI layer maps `code` to user-facing
/// strings; `message` is a fallback only and should not be parsed.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  /// Stable, uppercase, snake-case identifier — clients key on this.
  final String code;

  /// Human-readable message from the backend. Fallback for unmapped codes.
  final String message;

  /// HTTP status, when available.
  final int? statusCode;

  /// Optional structured details (e.g. per-field errors for `VALIDATION_ERROR`).
  final Map<String, dynamic>? details;

  /// Convert a raw [DioException] into an [ApiException]. Recognises both the
  /// backend's `{ "error": { "code", "message" } }` envelope and pure transport
  /// failures (timeouts, no connection).
  factory ApiException.fromDioException(DioException e) {
    final response = e.response;
    final data = response?.data;

    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        code: (err['code'] as String?) ?? 'UNKNOWN_ERROR',
        message: (err['message'] as String?) ?? e.message ?? 'Unknown error',
        statusCode: response?.statusCode,
        details: err['details'] is Map
            ? Map<String, dynamic>.from(err['details'] as Map)
            : null,
      );
    }

    final code = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'NETWORK_TIMEOUT',
      DioExceptionType.connectionError => 'NETWORK_ERROR',
      DioExceptionType.cancel => 'REQUEST_CANCELLED',
      _ => 'UNKNOWN_ERROR',
    };

    return ApiException(
      code: code,
      message: e.message ?? 'Network error',
      statusCode: response?.statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code: $message)';
}
