import 'dart:math';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/auth/data/pkce.dart';
import 'package:chubi_pocket/features/auth/domain/telegram_login.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _FakeApiClient extends Fake implements ApiClient {
  _FakeApiClient(this._dio);
  final Dio _dio;

  @override
  Dio get dio => _dio;
}

void main() {
  group('Pkce', () {
    test('the challenge matches the RFC 7636 test vector', () {
      expect(
        Pkce.challengeFor('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });

    test('a verifier is 64 unreserved characters and differs each time', () {
      final a = Pkce.newVerifier();
      final b = Pkce.newVerifier();
      expect(a.length, 64);
      expect(a, matches(RegExp(r'^[A-Za-z0-9._~-]{64}$')));
      expect(a, isNot(b));
    });

    test('a challenge is 43 base64url characters, no padding', () {
      final c = Pkce.challengeFor(Pkce.newVerifier(random: Random(1)));
      expect(c, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    });
  });

  group('AuthRepository · Telegram', () {
    late _MockDio dio;
    late AuthRepository repo;

    setUp(() {
      dio = _MockDio();
      repo = AuthRepository(client: _FakeApiClient(dio));
    });

    Response<Map<String, dynamic>> res(int status, Map<String, dynamic> body) =>
        Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ''),
          statusCode: status,
          data: body,
        );

    void stubPost(String path, Response<Map<String, dynamic>> answer) {
      when(
        () => dio.post<Map<String, dynamic>>(path, data: any(named: 'data')),
      ).thenAnswer((_) async => answer);
    }

    final userJson = {
      'id': 'u-1',
      'username': 'alice',
      'display_name': 'Alice',
      'currency': 'THB',
    };
    final authJson = {
      'user': userJson,
      'token': {'access_token': 'tok', 'expires_in': 2592000},
    };

    test('start sends the challenge and parses the link', () async {
      stubPost(
        '/auth/telegram/start',
        res(200, {
          'code': 'abc',
          'url': 'https://t.me/bot?start=login_abc',
          'expires_at': '2026-10-30T10:05:00Z',
        }),
      );

      final start = await repo.startTelegramLogin('challenge');

      expect(start.code, 'abc');
      expect(start.url, 'https://t.me/bot?start=login_abc');
      expect(start.expiresAt, DateTime.utc(2026, 10, 30, 10, 5));
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/telegram/start',
          data: {'code_challenge': 'challenge'},
        ),
      ).called(1);
    });

    test('exchange: pending (202), login and signup', () async {
      stubPost(
        '/auth/telegram/exchange',
        res(202, {'status': 'pending', 'auth': null, 'signup': null}),
      );
      expect(
        await repo.exchangeTelegramLogin(code: 'c', codeVerifier: 'v'),
        isA<TelegramPending>(),
      );

      stubPost(
        '/auth/telegram/exchange',
        res(200, {'status': 'login', 'auth': authJson, 'signup': null}),
      );
      final login =
          await repo.exchangeTelegramLogin(code: 'c', codeVerifier: 'v')
              as TelegramLoggedIn;
      expect(login.user.username, 'alice');
      expect(login.token.accessToken, 'tok');

      stubPost(
        '/auth/telegram/exchange',
        res(200, {
          'status': 'signup',
          'auth': null,
          'signup': {
            'display_name': 'Ann Lee',
            'username_suggestion': 'annlee',
            'has_photo': true,
          },
        }),
      );
      final signup =
          await repo.exchangeTelegramLogin(code: 'c', codeVerifier: 'v')
              as TelegramNeedsSignup;
      expect(signup.info.displayName, 'Ann Lee');
      expect(signup.info.usernameSuggestion, 'annlee');
      expect(signup.info.hasPhoto, isTrue);
    });

    test('exchange keeps the code and the verifier in the body', () async {
      stubPost(
        '/auth/telegram/exchange',
        res(202, {'status': 'pending', 'auth': null, 'signup': null}),
      );
      await repo.exchangeTelegramLogin(code: 'c1', codeVerifier: 'v1');
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/telegram/exchange',
          data: {'code': 'c1', 'code_verifier': 'v1'},
        ),
      ).called(1);
    });

    test('signup returns the signed-in answer', () async {
      stubPost('/auth/telegram/signup', res(201, authJson));

      final r = await repo.signupWithTelegram(
        code: 'c',
        codeVerifier: 'v',
        displayName: 'Alice',
        username: 'alice',
        currency: 'THB',
      );

      expect(r.user.id, 'u-1');
      expect(r.token.accessToken, 'tok');
    });

    test('an API error becomes an ApiException with its code', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/telegram/exchange',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {
              'error': {'code': 'LOGIN_CODE_INVALID', 'message': 'expired'},
            },
          ),
        ),
      );

      await expectLater(
        repo.exchangeTelegramLogin(code: 'c', codeVerifier: 'v'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'LOGIN_CODE_INVALID',
          ),
        ),
      );
    });
  });
}
