import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../storage/secure_token_storage.dart';
import 'http_logger_interceptor.dart';

/// API base URL — picks the right host depending on build flags/platform.
///
/// Priority:
/// 1. `--dart-define=API_BASE_URL=https://chubipocket-api.ppforge.dev/api/v1`
///    — full URL, used for **production/release builds** (APK via Firebase
///    App Distribution).
/// 2. `--dart-define=API_HOST=<lan-ip>` — dev on a **real** Android phone
///    (the phone can't reach `localhost` or `10.0.2.2`).
/// 3. Platform default: Android emulator → `10.0.2.2`; web/desktop →
///    `localhost`.
String _devBaseUrl() {
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (apiBaseUrl.isNotEmpty) {
    return apiBaseUrl;
  }
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
    Future<String?> Function()? appBuild,
  }) : _tokenStorage = tokenStorage,
       _dio = dio ?? Dio(),
       _appBuild = (appBuild ?? _platformBuild)() {
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
    _dio.interceptors.add(_outdatedNotifier());
  }

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;
  final StreamController<void> _unauthorizedController =
      StreamController<void>.broadcast();
  final StreamController<Map<String, dynamic>?> _outdatedController =
      StreamController<Map<String, dynamic>?>.broadcast();

  /// This app's build number (resolved once) — sent as `X-App-Build`.
  final Future<String?> _appBuild;

  Dio get dio => _dio;

  /// This app's build number as an int, or null when unknown.
  Future<int?> appBuild() async => int.tryParse(await _appBuild ?? '');

  /// Emits when any request returns a 401. The auth feature subscribes to
  /// clear the stored token and route to `/auth/login`.
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  /// Emits the error `details` (min / latest build, download URL, message)
  /// when any request comes back 426 `APP_OUTDATED` — the server refuses
  /// this build. The version gate subscribes and blocks at once.
  Stream<Map<String, dynamic>?> get onOutdated => _outdatedController.stream;

  static Future<String?> _platformBuild() async {
    try {
      return (await PackageInfo.fromPlatform()).buildNumber;
    } catch (_) {
      return null; // no build header — the server lets it through
    }
  }

  Interceptor _authInterceptor() => InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _tokenStorage.readAuthToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      // The version gate (BE contract v1): the server answers 426 when
      // this build is below its minimum.
      final build = await _appBuild;
      if (build != null && build.isNotEmpty) {
        options.headers['X-App-Build'] = build;
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

  Interceptor _outdatedNotifier() => InterceptorsWrapper(
    onError: (e, handler) {
      final data = e.response?.data;
      final error = data is Map && data['error'] is Map
          ? data['error'] as Map
          : null;
      if (e.response?.statusCode == 426 || error?['code'] == 'APP_OUTDATED') {
        final details = error?['details'];
        _outdatedController.add(
          details is Map ? Map<String, dynamic>.from(details) : null,
        );
      }
      handler.next(e);
    },
  );

  Future<void> dispose() async {
    await _unauthorizedController.close();
    await _outdatedController.close();
    _dio.close(force: true);
  }
}
