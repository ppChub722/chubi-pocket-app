import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_token_storage.dart';
import 'http_logger_interceptor.dart';

/// Dev API base URL — picks the right host depending on the running platform.
///
/// - Override via `--dart-define=API_HOST=<lan-ip>` when running on a **real**
///   Android phone (the phone can't reach `localhost` or `10.0.2.2`).
/// - Web / iOS sim / desktop: `localhost` reaches the host directly.
/// - Android emulator: the host's `localhost` is reachable as `10.0.2.2`.
String _devBaseUrl() {
  const apiHost = String.fromEnvironment('API_HOST');
  if (apiHost.isNotEmpty) {
    return 'http://$apiHost:8080/api/v1';
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080/api/v1';
  }
  return 'http://localhost:8080/api/v1';
}

/// Single shared HTTP client. Owns the [Dio] instance, attaches the auth
/// header from [SecureTokenStorage], and exposes [onUnauthorized] so the auth
/// feature can react to 401 responses (clear token, route to login).
///
/// Repositories receive an [ApiClient] via constructor injection and call
/// [dio] directly. They catch [DioException] and convert via
/// `ApiException.fromDioException`.
class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    Dio? dio,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl ?? _devBaseUrl()
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 15)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';

    // Order matters: auth runs first so the bearer token is attached
    // BEFORE the logger captures the headers (which redacts it on the
    // way out — we don't want the raw token in any log line). The
    // unauthorized notifier sits last so 401 is observed on the inbound
    // path.
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(HttpLoggerInterceptor());
    _dio.interceptors.add(_unauthorizedNotifier());
  }

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;
  final StreamController<void> _unauthorizedController =
      StreamController<void>.broadcast();

  Dio get dio => _dio;

  /// Emits when any request returns a 401. The auth feature subscribes to
  /// clear the stored token and route to `/auth/login`.
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  Interceptor _authInterceptor() => InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      );

  Interceptor _unauthorizedNotifier() => InterceptorsWrapper(
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            _unauthorizedController.add(null);
          }
          handler.next(e);
        },
      );

  Future<void> dispose() async {
    await _unauthorizedController.close();
    _dio.close(force: true);
  }
}
