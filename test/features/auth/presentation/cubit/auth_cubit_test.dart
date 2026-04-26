import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/auth/domain/auth_token.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

/// Stand-in for [ApiClient] — only [onUnauthorized] is consumed by [AuthCubit].
class _FakeApiClient extends Fake implements ApiClient {
  _FakeApiClient(this._controller);
  final StreamController<void> _controller;

  @override
  Stream<void> get onUnauthorized => _controller.stream;
}

const _user = User(
  id: 'u-1',
  username: 'alice',
  displayName: 'Alice',
  currency: 'THB',
);
const _token = AuthToken(accessToken: 'tok', expiresIn: 2592000);

const _networkErr = ApiException(code: 'NETWORK_ERROR', message: 'no net');

void main() {
  late _MockAuthRepository repo;
  late _MockSecureTokenStorage tokens;
  late StreamController<void> unauthorizedCtrl;
  late _FakeApiClient apiClient;

  setUp(() {
    repo = _MockAuthRepository();
    tokens = _MockSecureTokenStorage();
    unauthorizedCtrl = StreamController<void>.broadcast();
    apiClient = _FakeApiClient(unauthorizedCtrl);

    // Storage stubs the cubit calls in nearly every flow.
    when(() => tokens.readAuthToken()).thenAnswer((_) async => null);
    when(() => tokens.writeAuthToken(any())).thenAnswer((_) async {});
    when(() => tokens.clearAuthToken()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await unauthorizedCtrl.close();
  });

  AuthCubit build() => AuthCubit(
        repository: repo,
        tokenStorage: tokens,
        apiClient: apiClient,
      );

  group('init()', () {
    blocTest<AuthCubit, AuthState>(
      'no stored token → AuthUnauthenticated',
      build: () {
        when(() => tokens.readAuthToken()).thenAnswer((_) async => null);
        return build();
      },
      act: (c) => c.init(),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'valid token + repo returns user → AuthAuthenticated',
      build: () {
        when(() => tokens.readAuthToken()).thenAnswer((_) async => 'tok');
        when(() => repo.getCurrentUser()).thenAnswer((_) async => _user);
        return build();
      },
      act: (c) => c.init(),
      expect: () => [const AuthAuthenticated(_user)],
    );

    blocTest<AuthCubit, AuthState>(
      'valid token but repo throws → clears token + AuthUnauthenticated',
      build: () {
        when(() => tokens.readAuthToken()).thenAnswer((_) async => 'stale');
        when(() => repo.getCurrentUser()).thenThrow(_networkErr);
        return build();
      },
      act: (c) => c.init(),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) {
        verify(() => tokens.clearAuthToken()).called(1);
      },
    );
  });

  group('login()', () {
    blocTest<AuthCubit, AuthState>(
      'success → [Loading, Authenticated]; writes token',
      build: () {
        when(() => repo.login(
              identifier: any(named: 'identifier'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => (user: _user, token: _token));
        return build();
      },
      act: (c) => c.login(identifier: 'alice', password: 'pw'),
      expect: () => [
        const AuthLoading(AuthInitial()),
        const AuthAuthenticated(_user),
      ],
      verify: (_) {
        verify(() => tokens.writeAuthToken('tok')).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'failure → [Loading, Failure(prev=Initial)]; no token write',
      build: () {
        when(() => repo.login(
              identifier: any(named: 'identifier'),
              password: any(named: 'password'),
            )).thenThrow(const ApiException(
          code: 'INVALID_CREDENTIALS',
          message: 'bad',
        ));
        return build();
      },
      act: (c) => c.login(identifier: 'alice', password: 'wrong'),
      expect: () => [
        const AuthLoading(AuthInitial()),
        isA<AuthFailure>()
            .having((f) => f.error.code, 'code', 'INVALID_CREDENTIALS')
            .having((f) => f.previous, 'previous', const AuthInitial()),
      ],
      verify: (_) {
        verifyNever(() => tokens.writeAuthToken(any()));
      },
    );
  });

  group('register()', () {
    blocTest<AuthCubit, AuthState>(
      'success → [Loading, Authenticated]',
      build: () {
        when(() => repo.register(
              username: any(named: 'username'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
              email: any(named: 'email'),
              currency: any(named: 'currency'),
            )).thenAnswer((_) async => (user: _user, token: _token));
        return build();
      },
      act: (c) => c.register(
        username: 'alice',
        password: 'pw',
        displayName: 'Alice',
      ),
      expect: () => [
        const AuthLoading(AuthInitial()),
        const AuthAuthenticated(_user),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'USERNAME_EXISTS → [Loading, Failure]',
      build: () {
        when(() => repo.register(
              username: any(named: 'username'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
              email: any(named: 'email'),
              currency: any(named: 'currency'),
            )).thenThrow(const ApiException(
          code: 'USERNAME_EXISTS',
          message: 'taken',
        ));
        return build();
      },
      act: (c) => c.register(
        username: 'alice',
        password: 'pw',
        displayName: 'Alice',
      ),
      expect: () => [
        const AuthLoading(AuthInitial()),
        isA<AuthFailure>()
            .having((f) => f.error.code, 'code', 'USERNAME_EXISTS'),
      ],
    );
  });

  group('logout()', () {
    blocTest<AuthCubit, AuthState>(
      'from authenticated → [Loading, Unauthenticated]; clears token',
      build: () {
        when(() => repo.logout()).thenAnswer((_) async {});
        return build();
      },
      seed: () => const AuthAuthenticated(_user),
      act: (c) => c.logout(),
      expect: () => [
        const AuthLoading(AuthAuthenticated(_user)),
        const AuthUnauthenticated(),
      ],
      verify: (_) {
        verify(() => tokens.clearAuthToken()).called(1);
      },
    );
  });

  group('changePassword()', () {
    blocTest<AuthCubit, AuthState>(
      'success → restores previous Authenticated state',
      build: () {
        when(() => repo.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
            )).thenAnswer((_) async {});
        return build();
      },
      seed: () => const AuthAuthenticated(_user),
      act: (c) =>
          c.changePassword(currentPassword: 'old', newPassword: 'new12345'),
      expect: () => [
        const AuthLoading(AuthAuthenticated(_user)),
        const AuthAuthenticated(_user),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'WRONG_PASSWORD → [Loading, Failure]; identity preserved',
      build: () {
        when(() => repo.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
            )).thenThrow(const ApiException(
          code: 'WRONG_PASSWORD',
          message: 'wrong',
        ));
        return build();
      },
      seed: () => const AuthAuthenticated(_user),
      act: (c) =>
          c.changePassword(currentPassword: 'old', newPassword: 'new12345'),
      expect: () => [
        const AuthLoading(AuthAuthenticated(_user)),
        isA<AuthFailure>()
            .having((f) => f.error.code, 'code', 'WRONG_PASSWORD')
            .having((f) => f.previous, 'previous',
                const AuthAuthenticated(_user))
            .having((f) => f.isAuthenticated, 'isAuthenticated', true),
      ],
    );
  });

  group('acknowledgeFailure()', () {
    blocTest<AuthCubit, AuthState>(
      'unwraps Failure to its previous state',
      build: build,
      seed: () => AuthFailure(
        error: const ApiException(code: 'X', message: 'x'),
        previous: const AuthAuthenticated(_user),
      ),
      act: (c) => c.acknowledgeFailure(),
      expect: () => [const AuthAuthenticated(_user)],
    );

    blocTest<AuthCubit, AuthState>(
      'no-op when state is not a Failure',
      build: build,
      seed: () => const AuthAuthenticated(_user),
      act: (c) => c.acknowledgeFailure(),
      expect: () => const <AuthState>[],
    );
  });

  group('updateUser()', () {
    const newUser = User(
      id: 'u-1',
      username: 'alice',
      displayName: 'Alice S.',
      currency: 'USD',
    );

    blocTest<AuthCubit, AuthState>(
      'replaces user when authenticated',
      build: build,
      seed: () => const AuthAuthenticated(_user),
      act: (c) => c.updateUser(newUser),
      expect: () => [const AuthAuthenticated(newUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'no-op when not authenticated',
      build: build,
      seed: () => const AuthUnauthenticated(),
      act: (c) => c.updateUser(newUser),
      expect: () => const <AuthState>[],
    );
  });

  group('onUnauthorized event', () {
    blocTest<AuthCubit, AuthState>(
      'when authenticated, clears token + emits Unauthenticated',
      build: build,
      seed: () => const AuthAuthenticated(_user),
      act: (_) async {
        unauthorizedCtrl.add(null);
        // Let the listener microtask run.
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [const AuthUnauthenticated()],
      verify: (_) {
        verify(() => tokens.clearAuthToken()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'when not authenticated, ignores the event',
      build: build,
      seed: () => const AuthUnauthenticated(),
      act: (_) async {
        unauthorizedCtrl.add(null);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => const <AuthState>[],
    );
  });
}
