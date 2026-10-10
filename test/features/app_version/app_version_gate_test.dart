import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/app_version/data/app_version_repository.dart';
import 'package:chubi_pocket/features/app_version/domain/app_version_info.dart';
import 'package:chubi_pocket/features/app_version/presentation/cubit/app_version_cubit.dart';
import 'package:chubi_pocket/features/app_version/presentation/pages/update_required_page.dart';
import 'package:chubi_pocket/features/app_version/presentation/version_gate.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

    test('starts out checking (the splash holds)', () {
      final c = cubit(build: 42, fetch: () async => info);
      expect(c.state.status, AppVersionStatus.checking);
    });

    test('build below min → blocked', () async {
      final c = cubit(build: 40, fetch: () async => info);
      await c.check();
      expect(c.state.status, AppVersionStatus.updateRequired);
      expect(c.state.blocked, isTrue);
    });

    test('build below latest → the banner', () async {
      final c = cubit(build: 42, fetch: () async => info);
      await c.check();
      expect(c.state.status, AppVersionStatus.updateAvailable);
      expect(c.state.showBanner, isTrue);
    });

    test('up to date, or the check off (0s) → ok', () async {
      final c = cubit(build: 43, fetch: () async => info);
      await c.check();
      expect(c.state.status, AppVersionStatus.ok);
      final off = cubit(build: 1, fetch: () async => const AppVersionInfo());
      await off.check();
      expect(off.state.status, AppVersionStatus.ok);
    });

    test('a failed check lets the user in (offline / 5xx)', () async {
      final c = cubit(build: 1, fetch: () async => throw Exception('offline'));
      await c.check();
      expect(c.state.status, AppVersionStatus.ok);
    });

    test('a check that hangs times out and lets the user in', () async {
      final c = cubit(
        build: 1,
        fetch: () => Completer<AppVersionInfo>().future,
      );
      await c.check();
      expect(c.state.status, AppVersionStatus.ok);
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

  group('versionGateRedirect', () {
    test('blocked: everything goes to the gate', () {
      for (final loc in ['/', '/auth/login', '/accounts/1', '/more']) {
        expect(
          versionGateRedirect(loc, blocked: true),
          updateRequiredPath,
          reason: loc,
        );
      }
      expect(versionGateRedirect(updateRequiredPath, blocked: true), isNull);
    });

    test('/dev is exempt', () {
      expect(versionGateRedirect('/dev', blocked: true), isNull);
      expect(versionGateRedirect('/dev/widgets', blocked: true), isNull);
    });

    test('not blocked: nothing moves; the gate page sends you home', () {
      expect(versionGateRedirect('/accounts', blocked: false), isNull);
      expect(versionGateRedirect(updateRequiredPath, blocked: false), '/');
    });
  });

  // ── The page ───────────────────────────────────────────────────────

  group('UpdateRequiredView', () {
    Future<void> pump(WidgetTester t, AppVersionInfo info) => t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UpdateRequiredView(info: info, currentBuild: 40),
      ),
    );

    testWidgets('the server\'s message, and the download button', (t) async {
      await pump(
        t,
        const AppVersionInfo(
          minBuild: 41,
          downloadUrl: 'https://example.com/apk',
          messageTh: 'อัปเดตก่อนนะ',
        ),
      );
      expect(find.text('ต้องอัปเดตก่อนใช้งาน'), findsOneWidget);
      expect(find.text('อัปเดตก่อนนะ'), findsOneWidget);
      expect(find.text('ดาวน์โหลดเวอร์ชันใหม่'), findsOneWidget);
    });

    testWidgets('no link → the default text and a note', (t) async {
      await pump(t, const AppVersionInfo(minBuild: 41));
      expect(
        find.text(
          'แอปเวอร์ชันนี้เก่าเกินไปแล้ว ดาวน์โหลดเวอร์ชันใหม่เพื่อใช้งานต่อ',
        ),
        findsOneWidget,
      );
      expect(
        find.text('ยังไม่มีลิงก์ดาวน์โหลด — ติดต่อผู้ดูแล'),
        findsOneWidget,
      );
    });
  });
}
