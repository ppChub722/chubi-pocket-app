import 'dart:math';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/auth/data/pkce.dart';
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

    final authJson = {
      'user': {
        'id': 'u-1',
        'username': 'alice',
        'display_name': 'Alice',
        'currency': 'THB',
      },
      'token': {'access_token': 'tok', 'expires_in': 2592000},
    };

    void stubToken(Response<Map<String, dynamic>> answer) => when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/telegram/token',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => answer);

    test('login sends the id_token; 200 = an existing account', () async {
      stubToken(res(200, {'status': 'login', 'auth': authJson}));

      final r = await repo.telegramLogin('jwt');

      expect(r.user.username, 'alice');
      expect(r.token.accessToken, 'tok');
      expect(r.isNew, isFalse);
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/telegram/token',
          data: {'id_token': 'jwt'},
        ),
      ).called(1);
    });

    test('201 signup = a new member', () async {
      stubToken(res(201, {'status': 'signup', 'auth': authJson}));
      expect((await repo.telegramLogin('jwt')).isNew, isTrue);
    });

    test('an API error becomes an ApiException with its code', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/telegram/token',
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
              'error': {'code': 'TELEGRAM_TOKEN_INVALID', 'message': 'x'},
            },
          ),
        ),
      );

      await expectLater(
        repo.telegramLogin('jwt'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'TELEGRAM_TOKEN_INVALID',
          ),
        ),
      );
    });
  });
}
