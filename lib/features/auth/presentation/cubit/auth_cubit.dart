import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/user.dart';

// ────────────────────────────────────────────────────────────────────────────
//  AuthState — sealed hierarchy.
//
//  Routing only cares about [isAuthenticated]. [AuthLoading] and [AuthFailure]
//  preserve the previous identity so the user is not bounced to /auth/login
//  while a login / change-password / logout call is in flight.
// ────────────────────────────────────────────────────────────────────────────

sealed class AuthState extends Equatable {
  const AuthState();

  /// Whether the user is currently considered logged in. The router uses this.
  bool get isAuthenticated;

  @override
  List<Object?> get props => const [];
}

/// Cold-start, before [AuthCubit.init] resolves the stored token.
class AuthInitial extends AuthState {
  const AuthInitial();
  @override
  bool get isAuthenticated => false;
}

/// An auth action is in flight (login / register / logout / changePassword
/// / cold-start token validation). Wraps the previous state so the router
/// keeps the user on the right side of the auth gate.
class AuthLoading extends AuthState {
  const AuthLoading(this.previous);
  final AuthState previous;

  @override
  bool get isAuthenticated => previous.isAuthenticated;

  @override
  List<Object?> get props => [previous];
}

/// User is signed in. Token is held in secure storage; the cubit only carries
/// the [User].
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;

  @override
  bool get isAuthenticated => true;

  @override
  List<Object?> get props => [user];
}

/// User is signed out (or has never signed in).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
  @override
  bool get isAuthenticated => false;
}

/// Last action failed. The screen reads [error] to display feedback. The
/// underlying identity is preserved in [previous] so routing is stable.
class AuthFailure extends AuthState {
  const AuthFailure({required this.error, required this.previous});
  final ApiException error;
  final AuthState previous;

  @override
  bool get isAuthenticated => previous.isAuthenticated;

  @override
  List<Object?> get props => [error, previous];
}

// ────────────────────────────────────────────────────────────────────────────
//  AuthCubit — the reference Cubit that Phase 1+ modules copy.
// ────────────────────────────────────────────────────────────────────────────

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    required SecureTokenStorage tokenStorage,
    required ApiClient apiClient,
  })  : _repo = repository,
        _tokens = tokenStorage,
        super(const AuthInitial()) {
    _unauthorizedSub = apiClient.onUnauthorized.listen((_) => _onUnauthorized());
  }

  final AuthRepository _repo;
  final SecureTokenStorage _tokens;
  late final StreamSubscription<void> _unauthorizedSub;

  /// Cold-start: read token from secure storage and validate via /users/me.
  /// Stays on [AuthInitial] for the duration of the call — the SplashPage's
  /// own spinner is the loading indicator. This keeps the router's "is auth
  /// resolved?" check to a single state type.
  ///
  /// Catches everything: any failure (network, malformed response, parse
  /// error) drops us to [AuthUnauthenticated] so the router can redirect.
  /// A 12 s wall-clock cap is the last line of defence against a hang.
  Future<void> init() async {
    if (state is! AuthInitial) return;
    try {
      final token = await _tokens.readAuthToken();
      if (token == null || token.isEmpty) {
        emit(const AuthUnauthenticated());
        return;
      }
      final user = await _repo
          .getCurrentUser()
          .timeout(const Duration(seconds: 12));
      emit(AuthAuthenticated(user));
    } catch (_) {
      // Token invalid, parse error, or timeout: treat as unauth.
      try {
        await _tokens.clearAuthToken();
      } catch (_) {/* best-effort */}
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final previous = state;
    emit(AuthLoading(previous));
    try {
      final res = await _repo.login(identifier: identifier, password: password);
      await _tokens.writeAuthToken(res.token.accessToken);
      emit(AuthAuthenticated(res.user));
    } on ApiException catch (e) {
      emit(AuthFailure(error: e, previous: previous));
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String displayName,
    String? email,
    String currency = 'THB',
  }) async {
    final previous = state;
    emit(AuthLoading(previous));
    try {
      final res = await _repo.register(
        username: username,
        password: password,
        displayName: displayName,
        email: email,
        currency: currency,
      );
      await _tokens.writeAuthToken(res.token.accessToken);
      emit(AuthAuthenticated(res.user));
    } on ApiException catch (e) {
      emit(AuthFailure(error: e, previous: previous));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final previous = state;
    emit(AuthLoading(previous));
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      // Identity unchanged — restore previous state.
      emit(previous);
    } on ApiException catch (e) {
      emit(AuthFailure(error: e, previous: previous));
    }
  }

  Future<void> logout() async {
    final previous = state;
    emit(AuthLoading(previous));
    await _repo.logout();
    await _tokens.clearAuthToken();
    emit(const AuthUnauthenticated());
  }

  /// Clear the [AuthFailure] wrapper so subsequent reads see the underlying
  /// identity. Screens call this after dismissing an error banner.
  void acknowledgeFailure() {
    final s = state;
    if (s is AuthFailure) emit(s.previous);
  }

  /// Replace the cached [User] after a successful profile edit. No-op when
  /// the user is not currently authenticated.
  void updateUser(User user) {
    if (state is AuthAuthenticated) emit(AuthAuthenticated(user));
  }

  /// Triggered by [ApiClient.onUnauthorized] — wipe token and route to login.
  Future<void> _onUnauthorized() async {
    if (state is! AuthAuthenticated) return;
    await _tokens.clearAuthToken();
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() async {
    await _unauthorizedSub.cancel();
    return super.close();
  }
}
