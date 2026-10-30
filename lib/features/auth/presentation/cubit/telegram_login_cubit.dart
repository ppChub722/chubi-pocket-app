import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/pkce.dart';
import '../../domain/telegram_login.dart';
import 'auth_cubit.dart';

enum TelegramLoginPhase {
  /// Nothing running.
  idle,

  /// Asking the server for the link.
  starting,

  /// The link is open in Telegram; the app asks if it was confirmed.
  waiting,

  /// The chat has no account: the sign-up page.
  signup,

  /// Creating the account.
  signingUp,

  /// The code ran out, was used, or the chat got linked meanwhile.
  expired,
}

class TelegramLoginState extends Equatable {
  const TelegramLoginState({
    this.phase = TelegramLoginPhase.idle,
    this.url,
    this.signup,
    this.checking = false,
    this.failure,
    this.failureId = 0,
  });

  final TelegramLoginPhase phase;

  /// The `t.me` link (to open again).
  final String? url;
  final TelegramSignupInfo? signup;

  /// An exchange call is in flight.
  final bool checking;

  /// The last failure (the page shows it once; [failureId] makes a repeat of
  /// the same error count as new).
  final ApiException? failure;
  final int failureId;

  TelegramLoginState copyWith({
    TelegramLoginPhase? phase,
    String? url,
    TelegramSignupInfo? signup,
    bool? checking,
    ApiException? failure,
    bool clearFailure = false,
  }) => TelegramLoginState(
    phase: phase ?? this.phase,
    url: url ?? this.url,
    signup: signup ?? this.signup,
    checking: checking ?? this.checking,
    failure: clearFailure ? null : (failure ?? this.failure),
    failureId: failure == null ? failureId : failureId + 1,
  );

  @override
  List<Object?> get props => [phase, url, signup, checking, failure, failureId];
}

/// "เข้าสู่ระบบด้วย Telegram" (PKCE): start → open Telegram → ask until it is
/// confirmed → sign in, or sign up when the chat has no account. The verifier
/// and the code live only here, in memory (a killed app starts over).
class TelegramLoginCubit extends Cubit<TelegramLoginState> {
  TelegramLoginCubit({
    required AuthRepository repository,
    required AuthCubit auth,
    DateTime Function()? now,
  }) : _repo = repository,
       _auth = auth,
       _now = now ?? DateTime.now,
       super(const TelegramLoginState());

  final AuthRepository _repo;
  final AuthCubit _auth;
  final DateTime Function() _now;

  String? _verifier;
  String? _code;
  DateTime? _expiresAt;

  /// Makes a new verifier, asks for the link and returns it to open (null =
  /// failed; [TelegramLoginState.failure] says why).
  Future<String?> start() async {
    if (state.phase == TelegramLoginPhase.starting) return null;
    emit(const TelegramLoginState(phase: TelegramLoginPhase.starting));
    final verifier = Pkce.newVerifier();
    try {
      final start = await _repo.startTelegramLogin(Pkce.challengeFor(verifier));
      _verifier = verifier;
      _code = start.code;
      _expiresAt = start.expiresAt;
      emit(
        TelegramLoginState(
          phase: TelegramLoginPhase.waiting,
          url: start.url,
          failureId: state.failureId,
        ),
      );
      return start.url;
    } on ApiException catch (e) {
      _forget();
      emit(_failed(TelegramLoginPhase.idle, e));
      return null;
    }
  }

  /// Asks if the user confirmed in Telegram (on resume, on a timer, on the
  /// retry button). Pending changes nothing.
  Future<void> check() async {
    if (state.phase != TelegramLoginPhase.waiting || state.checking) return;
    final code = _code;
    final verifier = _verifier;
    final expires = _expiresAt;
    if (code == null || verifier == null) return;
    if (expires != null && !_now().isBefore(expires)) {
      _forget();
      emit(const TelegramLoginState(phase: TelegramLoginPhase.expired));
      return;
    }
    emit(state.copyWith(checking: true));
    try {
      final res = await _repo.exchangeTelegramLogin(
        code: code,
        codeVerifier: verifier,
      );
      switch (res) {
        case TelegramPending():
          emit(state.copyWith(checking: false));
        case TelegramLoggedIn():
          _forget();
          emit(const TelegramLoginState());
          await _auth.signInWith((user: res.user, token: res.token));
        case TelegramNeedsSignup():
          emit(
            TelegramLoginState(
              phase: TelegramLoginPhase.signup,
              signup: res.info,
              failureId: state.failureId,
            ),
          );
      }
    } on ApiException catch (e) {
      if (e.code == 'LOGIN_CODE_INVALID') {
        _forget();
        emit(const TelegramLoginState(phase: TelegramLoginPhase.expired));
        return;
      }
      // A network blip: keep waiting, tell the user once.
      AppLogger.instance.warn('auth.telegram_exchange_failed code=${e.code}');
      emit(state.copyWith(checking: false, failure: e));
    }
  }

  Future<void> signup({
    required String displayName,
    required String username,
    required String currency,
  }) async {
    final code = _code;
    final verifier = _verifier;
    final info = state.signup;
    if (state.phase != TelegramLoginPhase.signup ||
        code == null ||
        verifier == null) {
      return;
    }
    emit(state.copyWith(phase: TelegramLoginPhase.signingUp));
    try {
      final res = await _repo.signupWithTelegram(
        code: code,
        codeVerifier: verifier,
        displayName: displayName,
        username: username,
        currency: currency,
      );
      _forget();
      emit(const TelegramLoginState());
      await _auth.signInWith(res);
    } on ApiException catch (e) {
      switch (e.code) {
        case 'USERNAME_EXISTS':
          // The server offers a free name: put it in the field.
          final free = e.details?['username_suggestion'];
          emit(
            _failed(
              TelegramLoginPhase.signup,
              e,
              signup: free is String && free.isNotEmpty && info != null
                  ? TelegramSignupInfo(
                      displayName: displayName,
                      usernameSuggestion: free,
                      hasPhoto: info.hasPhoto,
                    )
                  : info,
            ),
          );
        case 'LOGIN_CODE_INVALID' || 'TELEGRAM_ALREADY_LINKED':
          _forget();
          emit(_failed(TelegramLoginPhase.expired, e));
        default:
          emit(_failed(TelegramLoginPhase.signup, e, signup: info));
      }
    }
  }

  /// Back to nothing (cancel, or after an expired code was shown).
  void reset() {
    _forget();
    emit(TelegramLoginState(failureId: state.failureId));
  }

  TelegramLoginState _failed(
    TelegramLoginPhase phase,
    ApiException e, {
    TelegramSignupInfo? signup,
  }) => TelegramLoginState(
    phase: phase,
    signup: signup,
    failure: e,
    failureId: state.failureId + 1,
  );

  void _forget() {
    _verifier = null;
    _code = null;
    _expiresAt = null;
  }
}
