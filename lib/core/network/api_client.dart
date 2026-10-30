import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/write_effects.dart';
import '../storage/secure_token_storage.dart';
import 'api_exception.dart';
import 'http_logger_interceptor.dart';
import 'network_recorder.dart';

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

class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    Dio? dio,
    String? baseUrl,
    Future<String?> Function()? appBuild,
    Future<String?> Function()? timezone,
  }) : _tokenStorage = tokenStorage,
       _dio = dio ?? Dio(),
       _appBuild = (appBuild ?? _platformBuild)(),
       _timezone = (timezone ?? _platformTimezone)() {
    _dio.options
      ..baseUrl = baseUrl ?? _devBaseUrl()
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 15)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';

    _dio.interceptors.add(_pageLoadTimeouts());
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(HttpLoggerInterceptor());
    _dio.interceptors.add(NetworkRecorderInterceptor());
    _dio.interceptors.add(_unauthorizedNotifier());
    _dio.interceptors.add(_outdatedNotifier());
    _dio.interceptors.add(_reachability());
    _dio.interceptors.add(_syncVersionsReader());
    _dio.interceptors.add(_effectsReader());
  }

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;
  final StreamController<void> _unauthorizedController =
      StreamController<void>.broadcast();
  final StreamController<Map<String, dynamic>?> _outdatedController =
      StreamController<Map<String, dynamic>?>.broadcast();

  final StreamController<void> _unreachableController =
      StreamController<void>.broadcast();
  final StreamController<void> _reachableController =
      StreamController<void>.broadcast();

  final Future<String?> _appBuild;

  final Future<String?> _timezone;

  /// Gets the `X-Sync-Versions` of every response that carries one (successful writes).
  void Function(Map<String, String> versions)? onSyncVersions;

  Dio get dio => _dio;

  Future<int?> appBuild() async => int.tryParse(await _appBuild ?? '');

  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  Stream<Map<String, dynamic>?> get onOutdated => _outdatedController.stream;

  Stream<void> get onUnreachable => _unreachableController.stream;
  Stream<void> get onReachable => _reachableController.stream;

  static Future<String?> _platformTimezone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return null; // no header — the BE uses the user's stored timezone
    }
  }

  /// The pubspec build of [raw]: a split-per-abi APK's versionCode is
  /// 1000 × abi + build (arm64 170 → 2170).
  static String releaseBuild(String raw) {
    final n = int.tryParse(raw);
    return n != null && n >= 1000 ? '${n % 1000}' : raw;
  }

  static Future<String?> _platformBuild() async {
    // The web build is a dev tool: its number is pubspec's, not a release's.
    if (kIsWeb) return null;
    try {
      return releaseBuild((await PackageInfo.fromPlatform()).buildNumber);
    } catch (_) {
      return null; // no build header — the server lets it through
    }
  }

  static const Duration pageLoadConnectTimeout = Duration(seconds: 5);
  static const Duration pageLoadReceiveTimeout = Duration(seconds: 10);

  Interceptor _pageLoadTimeouts() => InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.method.toUpperCase() == 'GET') {
        if (_dio.options.connectTimeout == options.connectTimeout) {
          options.connectTimeout = pageLoadConnectTimeout;
        }
        if (_dio.options.receiveTimeout == options.receiveTimeout) {
          options.receiveTimeout = pageLoadReceiveTimeout;
        }
      }
      handler.next(options);
    },
  );

  Interceptor _authInterceptor() => InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _tokenStorage.readAuthToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      final build = await _appBuild;
      if (build != null && build.isNotEmpty) {
        options.headers['X-App-Build'] = build;
      }
      final tz = await _timezone;
      if (tz != null && tz.isNotEmpty) {
        options.headers['X-Timezone'] = tz;
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

  Interceptor _reachability() => InterceptorsWrapper(
    onResponse: (response, handler) {
      _reachableController.add(null);
      handler.next(response);
    },
    onError: (e, handler) {
      if (e.response != null) {
        _reachableController.add(null);
      } else if (ApiException.isNetworkFailure(e)) {
        _unreachableController.add(null);
      }
      handler.next(e);
    },
  );

  Interceptor _syncVersionsReader() => InterceptorsWrapper(
    onResponse: (response, handler) {
      final raw = response.headers.value(syncVersionsHeader);
      final versions = raw == null ? null : parseSyncVersions(raw);
      if (versions != null && versions.isNotEmpty) {
        onSyncVersions?.call(versions);
      }
      handler.next(response);
    },
  );

  /// 0.4.1-1 B2: a write's `effects` go to every cache that holds them.
  Interceptor _effectsReader() => InterceptorsWrapper(
    onResponse: (response, handler) {
      final effects = WriteEffects.of(response.data);
      if (effects != null) WriteEffectsBus.instance.publish(effects);
      handler.next(response);
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
    await _unreachableController.close();
    await _reachableController.close();
    _dio.close(force: true);
  }
}

const syncVersionsHeader = 'x-sync-versions';

/// `name=version;name=version` → map; a malformed pair is skipped.
Map<String, String> parseSyncVersions(String raw) {
  final out = <String, String>{};
  for (final pair in raw.split(';')) {
    final i = pair.indexOf('=');
    if (i <= 0) continue;
    out[pair.substring(0, i).trim()] = pair.substring(i + 1).trim();
  }
  return out;
}
