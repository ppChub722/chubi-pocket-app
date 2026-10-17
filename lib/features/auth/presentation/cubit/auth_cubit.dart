import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  bool get isAuthenticated;

  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial({this.startupError});

  final ApiException? startupError;

  @override
  bool get isAuthenticated => false;

  @override
  List<Object?> get props => [startupError];
}

class AuthLoading extends AuthState {
  const AuthLoading(this.previous);
  final AuthState previous;

  @override
  bool get isAuthenticated => previous.isAuthenticated;

  @override
  List<Object?> get props => [previous];
}

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

class AuthFailure extends AuthState {
  const AuthFailure({required this.error, required this.previous});
  final ApiException error;
  final AuthState previous;

  @override
  bool get isAuthenticated => previous.isAuthenticated;

  @override
  List<Object?> get props => [error, previous];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    required SecureTokenStorage tokenStorage,
    required ApiClient apiClient,
  }) : _repo = repository,
       _tokens = tokenStorage,
       super(const AuthInitial()) {
    _unauthorizedSub = apiClient.onUnauthorized.listen(
      (_) => _onUnauthorized(),
    );
  }

  final AuthRepository _repo;
  final SecureTokenStorage _tokens;
  late final StreamSubscription<void> _unauthorizedSub;

  Future<void> init() =>
      _initRun ??= _init().whenComplete(() => _initRun = null);

  Future<void>? _initRun;

  Future<void> _init() async {
    final s = state;
    if (s is! AuthInitial) return;
    if (s.startupError != null) emit(const AuthInitial());
    try {
      final token = await _tokens.readAuthToken();
      if (token == null || token.isEmpty) {
        emit(const AuthUnauthenticated());
        return;
      }
      final user = await _repo.getCurrentUser().timeout(
        const Duration(seconds: 12),
      );
      emit(AuthAuthenticated(user));
    } catch (e, st) {
      final error = e is TimeoutException
          ? const ApiException(code: 'NETWORK_TIMEOUT', message: 'timeout')
          : ApiException.from(e, st);
      final rejected = error.statusCode == 401 || error.statusCode == 403;
      if (!rejected) {
        AppLogger.instance.warn('auth.startup_check_failed code=${error.code}');
        emit(AuthInitial(startupError: error));
        return;
      }
      try {
        await _tokens.clearAuthToken();
      } catch (_) {
        /* best-effort */
      }
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
      AppLogger.instance.setUserId(res.user.id);
      AppLogger.instance.info(
        'auth.login_success',
        fields: {'user_id': res.user.id, 'username': res.user.username},
      );
      emit(AuthAuthenticated(res.user));
    } on ApiException catch (e) {
      AppLogger.instance.warn(
        'auth.login_failed',
        fields: {
          'identifier': identifier,
          'code': e.code,
          'status': e.statusCode,
        },
      );
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
      AppLogger.instance.setUserId(res.user.id);
      AppLogger.instance.info(
        'auth.register_success',
        fields: {'user_id': res.user.id, 'username': res.user.username},
      );
      emit(AuthAuthenticated(res.user));
    } on ApiException catch (e) {
      AppLogger.instance.warn(
        'auth.register_failed',
        fields: {'username': username, 'code': e.code, 'status': e.statusCode},
      );
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
      emit(previous);
    } on ApiException catch (e) {
      emit(AuthFailure(error: e, previous: previous));
    }
  }

  Future<void> logout() async {
    final previous = state;
    AppLogger.instance.info('auth.logout');
    emit(AuthLoading(previous));
    await _repo.logout();
    await _tokens.clearAuthToken();
    AppLogger.instance.setUserId(null);
    emit(const AuthUnauthenticated());
  }

  void acknowledgeFailure() {
    final s = state;
    if (s is AuthFailure) emit(s.previous);
  }

  void updateUser(User user) {
    if (state is AuthAuthenticated) emit(AuthAuthenticated(user));
  }

  Future<void> _onUnauthorized() async {
    if (state is! AuthAuthenticated) return;
    AppLogger.instance.warn('auth.unauthorized_kicked');
    await _tokens.clearAuthToken();
    AppLogger.instance.setUserId(null);
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() async {
    await _unauthorizedSub.cancel();
    return super.close();
  }
}
