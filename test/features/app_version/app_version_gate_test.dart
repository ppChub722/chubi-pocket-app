import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/features/app_version/data/app_version_repository.dart';
import 'package:chubi_pocket/features/app_version/domain/app_version_info.dart';
import 'package:chubi_pocket/features/app_version/presentation/cubit/app_version_cubit.dart';
import 'package:chubi_pocket/features/app_version/presentation/version_gate.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockTokens extends Mock implements SecureTokenStorage {}

/// Answers every request with [status] + [body] and remembers the request.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.status = 200, this.body = const {}});
  int status;
  Map<String, dynamic> body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRepo implements AppVersionRepository {
  _FakeRepo(this.onFetch);
  Future<AppVersionInfo> Function() onFetch;

  @override
  Future<AppVersionInfo> fetch() => onFetch();
}

ApiClient _client(_Adapter adapter, {String? build = '40'}) {
  final tokens = _MockTokens();
  when(tokens.readAuthToken).thenAnswer((_) async => null);
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    tokenStorage: tokens,
    dio: dio,
    baseUrl: 'http://test',
    appBuild: () async => build,
  );
}

const _outdatedBody = {
  'success': false,
  'error': {
    'code': 'APP_OUTDATED',
    'message': 'App build 40 is older than the minimum 41 — please update',
    'details': {
      'min_build': 41,
      'latest_build': 42,
      'download_url': 'https://example.com/apk',
      'message_th': 'อัปเดตก่อนนะ',
    },
  },
};

void main() {
  // ── The header ─────────────────────────────────────────────────────

  group('X-App-Build', () {
    test('sent on every request', () async {
      final adapter = _Adapter();
      final client = _client(adapter, build: '42');
      await client.dio.get<dynamic>('/accounts');
      expect(adapter.last!.headers['X-App-Build'], '42');
      await client.dio.post<dynamic>('/pending-transactions', data: {});
      expect(adapter.last!.headers['X-App-Build'], '42');
    });

    test('left out when the build is unknown', () async {
      final adapter = _Adapter();
      final client = _client(adapter, build: null);
      await client.dio.get<dynamic>('/accounts');
      expect(adapter.last!.headers.containsKey('X-App-Build'), isFalse);
    });
  });

  // ── 426 mid-session ────────────────────────────────────────────────

  test('a 426 APP_OUTDATED on any request emits its details', () async {
    final client = _client(_Adapter(status: 426, body: _outdatedBody));
    final next = client.onOutdated.first;
    await expectLater(
      client.dio.get<dynamic>('/dashboard'),
      throwsA(isA<DioException>()),
    );
    final details = await next;
    expect(details?['min_build'], 41);
    expect(details?['download_url'], 'https://example.com/apk');
  });

  // ── The check ──────────────────────────────────────────────────────

  group('AppVersionCubit.check', () {
    AppVersionCubit cubit({
      required int? build,
      required Future<AppVersionInfo> Function() fetch,
      SharedPreferences? prefs,
      DateTime Function()? now,
    }) => AppVersionCubit(
      repository: _FakeRepo(fetch),
      currentBuild: () async => build,
      prefs: prefs,
      now: now,
      timeout: const Duration(milliseconds: 50),
    );

    const info = AppVersionInfo(minBuild: 41, latestBuild: 43);

    test('status by build', () async {
      expect(
        cubit(build: 42, fetch: () async => info).state.status,
        AppVersionStatus.checking,
        reason: 'starts out checking (the splash holds)',
      );
      for (final c in <({
        String name,
        int build,
        AppVersionInfo info,
        AppVersionStatus status,
        bool blocked,
        bool banner,
      })>[
        (
          name: 'below min → blocked',
          build: 40,
          info: info,
          status: AppVersionStatus.updateRequired,
          blocked: true,
          banner: false,
        ),
        (
          name: 'below latest → the banner',
          build: 42,
          info: info,
          status: AppVersionStatus.updateAvailable,
          blocked: false,
          banner: true,
        ),
        (
          name: 'up to date → ok',
          build: 43,
          info: info,
          status: AppVersionStatus.ok,
          blocked: false,
          banner: false,
        ),
        (
          name: 'the check off (0s) → ok',
          build: 1,
          info: const AppVersionInfo(),
          status: AppVersionStatus.ok,
          blocked: false,
          banner: false,
        ),
      ]) {
        final k = cubit(build: c.build, fetch: () async => c.info);
        await k.check();
        expect(k.state.status, c.status, reason: c.name);
        expect(k.state.blocked, c.blocked, reason: c.name);
        expect(k.state.showBanner, c.banner, reason: c.name);
      }
    });

    test('a failed or hanging check lets the user in', () async {
      final failed = cubit(
        build: 1,
        fetch: () async => throw Exception('offline'),
      );
      await failed.check();
      expect(failed.state.status, AppVersionStatus.ok);
      final hung = cubit(
        build: 1,
        fetch: () => Completer<AppVersionInfo>().future,
      );
      await hung.check();
      expect(hung.state.status, AppVersionStatus.ok);
    });

    test('a failed re-check keeps a block it already knows of', () async {
      var fail = false;
      final c = cubit(
        build: 40,
        fetch: () async => fail ? throw Exception('offline') : info,
      );
      await c.check();
      fail = true;
      await c.check(); // app resumed, offline
      expect(c.state.blocked, isTrue);
    });

    test('the banner, once closed, stays away for a day', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var now = DateTime(2026, 10, 10, 9);
      final c = cubit(
        build: 42,
        fetch: () async => info,
        prefs: prefs,
        now: () => now,
      );
      await c.check();
      await c.dismissBanner();
      expect(c.state.showBanner, isFalse);
      now = now.add(const Duration(hours: 23));
      await c.check(); // resumed later the same day
      expect(c.state.showBanner, isFalse);
      now = now.add(const Duration(hours: 2));
      await c.check(); // the next day
      expect(c.state.showBanner, isTrue);
    });
  });

  // ── 426 → the gate ─────────────────────────────────────────────────

  test('426 on any request → blocked → every route goes to the gate', () async {
    final client = _client(_Adapter(status: 426, body: _outdatedBody));
    final c = AppVersionCubit(
      repository: _FakeRepo(() async => const AppVersionInfo()),
      currentBuild: client.appBuild,
      outdated: client.onOutdated,
    );
    await c.check(); // the server said ok at start…
    expect(c.state.blocked, isFalse);
    await expectLater(
      client.dio.get<dynamic>('/transactions'), // …then raised its minimum
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(c.state.blocked, isTrue);
    expect(c.state.info.downloadUrl, 'https://example.com/apk');
    expect(
      versionGateRedirect('/transactions', blocked: c.state.blocked),
      updateRequiredPath,
    );
  });

  // ── The redirect ───────────────────────────────────────────────────

  test('versionGateRedirect', () {
    for (final c in <({String loc, bool blocked, String? want})>[
      (loc: '/', blocked: true, want: updateRequiredPath),
      (loc: '/auth/login', blocked: true, want: updateRequiredPath),
      (loc: '/accounts/1', blocked: true, want: updateRequiredPath),
      (loc: '/more', blocked: true, want: updateRequiredPath),
      (loc: updateRequiredPath, blocked: true, want: null),
      (loc: '/dev', blocked: true, want: null),
      (loc: '/dev/widgets', blocked: true, want: null),
      (loc: '/accounts', blocked: false, want: null),
      (loc: updateRequiredPath, blocked: false, want: '/'),
    ]) {
      expect(
        versionGateRedirect(c.loc, blocked: c.blocked),
        c.want,
        reason: '${c.loc} blocked=${c.blocked}',
      );
    }
  });
}
