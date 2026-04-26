import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

/// Minimal stand-in for [ApiClient] — the repository only ever touches `.dio`.
class _FakeApiClient extends Fake implements ApiClient {
  _FakeApiClient(this._dio);
  final Dio _dio;

  @override
  Dio get dio => _dio;
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(RequestOptions(path: ''));
  });

  late _MockDio dio;
  late AuthRepository repo;

  setUp(() {
    dio = _MockDio();
    repo = AuthRepository(client: _FakeApiClient(dio));
  });

  Response<Map<String, dynamic>> ok(Map<String, dynamic> body) =>
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: body,
      );

  DioException dioErr({
    int? status,
    Map<String, dynamic>? body,
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    final req = RequestOptions(path: '');
    return DioException(
      requestOptions: req,
      type: type,
      response: status == null
          ? null
          : Response(requestOptions: req, statusCode: status, data: body),
    );
  }

  final userJson = {
    'id': '019dc999-20ee-7757-998f-90ae1e6bbb00',
    'username': 'alice',
    'email': 'alice@example.com',
    'display_name': 'Alice',
    'currency': 'THB',
    'avatar_url': null,
  };
  final tokenJson = {'access_token': 'eyJabc', 'expires_in': 2592000};

  group('AuthRepository.register', () {
    test('returns parsed user + token on 201', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/auth/register',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => ok({'user': userJson, 'token': tokenJson}),
      );

      final res = await repo.register(
        username: 'alice',
        password: 'pw',
        displayName: 'Alice',
      );

      expect(res.user.username, 'alice');
      expect(res.token.accessToken, 'eyJabc');
      expect(res.token.expiresIn, 2592000);
    });

    test('USERNAME_EXISTS → ApiException with envelope code', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/auth/register',
            data: any(named: 'data'),
          )).thenThrow(
        dioErr(
          status: 409,
          body: {
            'error': {
              'code': 'USERNAME_EXISTS',
              'message': 'Username already registered'
            }
          },
        ),
      );

      await expectLater(
        repo.register(
          username: 'alice',
          password: 'pw',
          displayName: 'Alice',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'USERNAME_EXISTS')
            .having((e) => e.statusCode, 'status', 409)),
      );
    });
  });

  group('AuthRepository.login', () {
    test('returns parsed user + token on 200', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/auth/login',
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => ok({'user': userJson, 'token': tokenJson}),
      );

      final res = await repo.login(identifier: 'alice', password: 'pw');

      expect(res.user.id, userJson['id']);
      expect(res.token.accessToken, 'eyJabc');
    });

    test('401 INVALID_CREDENTIALS → ApiException', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/auth/login',
            data: any(named: 'data'),
          )).thenThrow(
        dioErr(
          status: 401,
          body: {
            'error': {
              'code': 'INVALID_CREDENTIALS',
              'message': 'Invalid credentials',
            }
          },
        ),
      );

      await expectLater(
        repo.login(identifier: 'alice', password: 'wrong'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'INVALID_CREDENTIALS')
            .having((e) => e.statusCode, 'status', 401)),
      );
    });

    test('connection error → ApiException(NETWORK_ERROR)', () async {
      when(() => dio.post<Map<String, dynamic>>(
            '/auth/login',
            data: any(named: 'data'),
          )).thenThrow(dioErr(type: DioExceptionType.connectionError));

      await expectLater(
        repo.login(identifier: 'alice', password: 'pw'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
    });
  });

  group('AuthRepository.logout', () {
    test('returns normally on 200', () async {
      when(() => dio.post<void>('/auth/logout'))
          .thenAnswer((_) async => Response<void>(
                requestOptions: RequestOptions(path: ''),
                statusCode: 200,
              ));

      await expectLater(repo.logout(), completes);
    });

    test('swallows server errors (best-effort logout)', () async {
      when(() => dio.post<void>('/auth/logout'))
          .thenThrow(dioErr(status: 500));

      // Should NOT throw — server-side logout is best-effort in Phase 0/1.
      await expectLater(repo.logout(), completes);
    });
  });

  group('AuthRepository.changePassword', () {
    test('returns normally on success', () async {
      when(() => dio.put<void>('/auth/password', data: any(named: 'data')))
          .thenAnswer((_) async => Response<void>(
                requestOptions: RequestOptions(path: ''),
                statusCode: 200,
              ));

      await expectLater(
        repo.changePassword(currentPassword: 'old', newPassword: 'new12345'),
        completes,
      );
    });

    test('WRONG_PASSWORD → ApiException', () async {
      when(() => dio.put<void>('/auth/password', data: any(named: 'data')))
          .thenThrow(
        dioErr(
          status: 401,
          body: {
            'error': {'code': 'WRONG_PASSWORD', 'message': 'Wrong password'}
          },
        ),
      );

      await expectLater(
        repo.changePassword(currentPassword: 'wrong', newPassword: 'new12345'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'WRONG_PASSWORD')),
      );
    });
  });

  group('AuthRepository.getCurrentUser', () {
    test('returns parsed user on 200', () async {
      when(() => dio.get<Map<String, dynamic>>('/users/me'))
          .thenAnswer((_) async => ok(userJson));

      final user = await repo.getCurrentUser();

      expect(user.username, 'alice');
      expect(user.displayName, 'Alice');
    });

    test('401 UNAUTHORIZED → ApiException', () async {
      when(() => dio.get<Map<String, dynamic>>('/users/me')).thenThrow(
        dioErr(
          status: 401,
          body: {
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Authorization header required'
            }
          },
        ),
      );

      await expectLater(
        repo.getCurrentUser(),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'UNAUTHORIZED')
            .having((e) => e.statusCode, 'status', 401)),
      );
    });
  });
}
