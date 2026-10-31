import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/telegram_oidc.dart';
import 'auth_cubit.dart';

class TelegramLoginState extends Equatable {
  const TelegramLoginState({
    this.busy = false,
    this.failure,
    this.openFailed = false,
    this.failureId = 0,
  });

  /// Telegram is open, or the login call is running.
  final bool busy;

  /// The last failure (the login page shows it once; [failureId] makes a
  /// repeat count as new).
  final ApiException? failure;

  /// Telegram could not be opened at all.
  final bool openFailed;
  final int failureId;

  @override
  List<Object?> get props => [busy, failure, openFailed, failureId];
}

/// "เข้าสู่ระบบด้วย Telegram" (OIDC): Telegram's consent sheet → id_token →
/// POST /auth/telegram/token → signed in. An unknown Telegram gets an
/// account at once, no form.
class TelegramLoginCubit extends Cubit<TelegramLoginState> {
  TelegramLoginCubit({
    required AuthRepository repository,
    required AuthCubit auth,
    required TelegramOidc oidc,
  }) : _repo = repository,
       _auth = auth,
       _oidc = oidc,
       super(const TelegramLoginState());

  final AuthRepository _repo;
  final AuthCubit _auth;
  final TelegramOidc _oidc;

  Future<void> signIn() async {
    if (state.busy) return;
    emit(TelegramLoginState(busy: true, failureId: state.failureId));
    try {
      final token = await _oidc.signIn(TelegramOidcPurpose.login);
      if (token == null) {
        emit(TelegramLoginState(failureId: state.failureId));
        return;
      }
      await _finish(token);
    } on TelegramOidcOpenFailed {
      emit(TelegramLoginState(openFailed: true, failureId: state.failureId + 1));
    } on TelegramOidcException catch (e) {
      AppLogger.instance.warn('auth.telegram_oidc_failed ${e.message}');
      _fail(ApiException.from(e, StackTrace.current));
    } on ApiException catch (e) {
      _fail(e);
    }
  }

  /// A login whose redirect came back after Android killed the app while
  /// Telegram was open (called once at start-up).
  Future<void> resumePending() async {
    try {
      final pending = await _oidc.resume();
      if (pending == null || pending.purpose != TelegramOidcPurpose.login) {
        return;
      }
      emit(TelegramLoginState(busy: true, failureId: state.failureId));
      await _finish(pending.token);
    } on TelegramOidcException catch (e) {
      AppLogger.instance.warn('auth.telegram_oidc_resume_failed ${e.message}');
    } on ApiException catch (e) {
      _fail(e);
    }
  }

  void cancel() => _oidc.cancel();

  Future<void> _finish(String idToken) async {
    final res = await _repo.telegramLogin(idToken);
    emit(TelegramLoginState(failureId: state.failureId));
    await _auth.signInWith((user: res.user, token: res.token));
  }

  void _fail(ApiException e) => emit(
    TelegramLoginState(failure: e, failureId: state.failureId + 1),
  );
}
