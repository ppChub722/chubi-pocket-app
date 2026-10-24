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

  Map<String, dynamic> envelope(String code, String message) => {
    'error': {'code': code, 'message': message},
  };

  final userJson = {
    'id': '019dc999-20ee-7757-998f-90ae1e6bbb00',
    'username': 'alice',
    'email': 'alice@example.com',
    'display_name': 'Alice',
    'currency': 'THB',
    'avatar_url': null,
  };
  final tokenJson = {'access_token': 'eyJabc', 'expires_in': 2592000};

  void stubPost(String path, Object answer) {
    final call = when(
      () => dio.post<Map<String, dynamic>>(path, data: any(named: 'data')),
    );
    if (answer is DioException) {
      call.thenThrow(answer);
    } else {
      call.thenAnswer((_) async => answer as Response<Map<String, dynamic>>);
    }
  }

  void stubPassword(Future<Response<void>> Function() answer) {
    when(
      () => dio.put<void>('/auth/password', data: any(named: 'data')),
    ).thenAnswer((_) => answer());
  }

  test('register and login parse the user and the token', () async {
    stubPost('/auth/register', ok({'user': userJson, 'token': tokenJson}));
    stubPost('/auth/login', ok({'user': userJson, 'token': tokenJson}));

    final registered = await repo.register(
      username: 'alice',
      password: 'pw',
      displayName: 'Alice',
    );
    final loggedIn = await repo.login(identifier: 'alice', password: 'pw');

    for (final res in [registered, loggedIn]) {
      expect(res.user.id, userJson['id']);
      expect(res.user.username, 'alice');
      expect(res.token.accessToken, 'eyJabc');
      expect(res.token.expiresIn, 2592000);
    }
  });

  test('getCurrentUser parses /users/me', () async {
    when(
      () => dio.get<Map<String, dynamic>>('/users/me'),
    ).thenAnswer((_) async => ok(userJson));

    final user = await repo.getCurrentUser();

    expect(user.username, 'alice');
    expect(user.displayName, 'Alice');
  });

  test('error envelope: code and status come through', () async {
    stubPassword(
      () async => throw dioErr(
        status: 401,
        body: envelope('WRONG_PASSWORD', 'Wrong password'),
      ),
    );
    final cases = <({String name, Future<void> Function() call, String code, int status})>[
      (
        name: 'register',
        call: () {
          stubPost(
            '/auth/register',
            dioErr(
              status: 409,
              body: envelope('USERNAME_EXISTS', 'Username already registered'),
            ),
          );
          return repo.register(
            username: 'alice',
            password: 'pw',
            displayName: 'Alice',
          );
        },
        code: 'USERNAME_EXISTS',
        status: 409,
      ),
      (
        name: 'login',
        call: () {
          stubPost(
            '/auth/login',
            dioErr(
              status: 401,
              body: envelope('INVALID_CREDENTIALS', 'Invalid credentials'),
            ),
          );
          return repo.login(identifier: 'alice', password: 'wrong');
        },
        code: 'INVALID_CREDENTIALS',
        status: 401,
      ),
      (
        name: 'changePassword',
        call: () => repo.changePassword(
          currentPassword: 'wrong',
          newPassword: 'new12345',
        ),
        code: 'WRONG_PASSWORD',
        status: 401,
      ),
      (
        name: '/users/me',
        call: () {
          when(() => dio.get<Map<String, dynamic>>('/users/me')).thenThrow(
            dioErr(
              status: 401,
              body: envelope('UNAUTHORIZED', 'Authorization header required'),
            ),
          );
          return repo.getCurrentUser();
        },
        code: 'UNAUTHORIZED',
        status: 401,
      ),
    ];

    for (final c in cases) {
      await expectLater(
        c.call(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', c.code)
              .having((e) => e.statusCode, 'status', c.status),
        ),
        reason: c.name,
      );
    }
  });

  test('connection error → ApiException(NETWORK_ERROR)', () async {
    stubPost('/auth/login', dioErr(type: DioExceptionType.connectionError));

    await expectLater(
      repo.login(identifier: 'alice', password: 'pw'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'NETWORK_ERROR'),
      ),
    );
  });

  test('logout completes, and swallows a server error', () async {
    when(() => dio.post<void>('/auth/logout')).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
      ),
    );
    await expectLater(repo.logout(), completes);

    when(() => dio.post<void>('/auth/logout')).thenThrow(dioErr(status: 500));
    await expectLater(repo.logout(), completes);
  });

  test('changePassword completes on success', () async {
    stubPassword(
      () async => Response<void>(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
      ),
    );

    await expectLater(
      repo.changePassword(currentPassword: 'old', newPassword: 'new12345'),
      completes,
    );
  });
}
