import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/auth/data/pkce.dart';
import 'package:chubi_pocket/features/auth/domain/auth_token.dart';
import 'package:chubi_pocket/features/auth/domain/telegram_login.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/telegram_login_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _MockAuth extends Mock implements AuthCubit {}

const _user = User(
  id: 'u-1',
  username: 'alice',
  displayName: 'Alice',
  currency: 'THB',
);
const _token = AuthToken(accessToken: 'tok', expiresIn: 2592000);
final _expires = DateTime.utc(2026, 10, 30, 10, 5);
final _start = TelegramLoginStart(
  code: 'code-1',
  url: 'https://t.me/bot?start=login_code-1',
  expiresAt: _expires,
);
const _info = TelegramSignupInfo(
  displayName: 'Ann Lee',
  usernameSuggestion: 'annlee',
  hasPhoto: true,
);

ApiException _err(String code, {int status = 400, Map<String, dynamic>? d}) =>
    ApiException(code: code, message: code, statusCode: status, details: d);

void main() {
  late _MockRepo repo;
  late _MockAuth auth;
  var now = DateTime.utc(2026, 10, 30, 10);

  TelegramLoginCubit make() =>
      TelegramLoginCubit(repository: repo, auth: auth, now: () => now);

  setUpAll(() {
    registerFallbackValue((user: _user, token: _token));
  });

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    now = DateTime.utc(2026, 10, 30, 10);
    when(() => auth.signInWith(any())).thenAnswer((_) async {});
    when(() => repo.startTelegramLogin(any())).thenAnswer((_) async => _start);
  });

  void exchange(Object answer) {
    final call = when(
      () => repo.exchangeTelegramLogin(
        code: any(named: 'code'),
        codeVerifier: any(named: 'codeVerifier'),
      ),
    );
    if (answer is Exception) {
      call.thenThrow(answer);
    } else {
      call.thenAnswer((_) async => answer as TelegramExchange);
    }
  }

  test('start sends only the challenge, keeps the link and waits', () async {
    final cubit = make();

    final url = await cubit.start();

    expect(url, _start.url);
    expect(cubit.state.phase, TelegramLoginPhase.waiting);
    expect(cubit.state.url, _start.url);
    final challenge =
        verify(() => repo.startTelegramLogin(captureAny())).captured.single
            as String;
    expect(challenge, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
  });

  test('a failed start goes back to idle with the failure', () async {
    when(
      () => repo.startTelegramLogin(any()),
    ).thenThrow(_err('CONNECTION_UNAVAILABLE', status: 409));
    final cubit = make();

    expect(await cubit.start(), isNull);

    expect(cubit.state.phase, TelegramLoginPhase.idle);
    expect(cubit.state.failure?.code, 'CONNECTION_UNAVAILABLE');
  });

  test('pending changes nothing and the next check can run', () async {
    final cubit = make();
    await cubit.start();
    exchange(const TelegramPending());

    await cubit.check();

    expect(cubit.state.phase, TelegramLoginPhase.waiting);
    expect(cubit.state.checking, isFalse);
    await cubit.check();
    verify(
      () => repo.exchangeTelegramLogin(
        code: 'code-1',
        codeVerifier: any(named: 'codeVerifier'),
      ),
    ).called(2);
  });

  test('the verifier sent to exchange hashes to the start challenge', () async {
    final cubit = make();
    await cubit.start();
    exchange(const TelegramPending());
    await cubit.check();

    final challenge =
        verify(() => repo.startTelegramLogin(captureAny())).captured.single
            as String;
    final verifier =
        verify(
              () => repo.exchangeTelegramLogin(
                code: any(named: 'code'),
                codeVerifier: captureAny(named: 'codeVerifier'),
              ),
            ).captured.single
            as String;
    expect(Pkce.challengeFor(verifier), challenge);
  });

  test('a confirmed login signs the app in and clears the flow', () async {
    final cubit = make();
    await cubit.start();
    exchange(const TelegramLoggedIn(user: _user, token: _token));

    await cubit.check();

    expect(cubit.state.phase, TelegramLoginPhase.idle);
    verify(() => auth.signInWith(any())).called(1);
  });

  test('a chat with no account opens the sign-up with the prefill', () async {
    final cubit = make();
    await cubit.start();
    exchange(const TelegramNeedsSignup(_info));

    await cubit.check();

    expect(cubit.state.phase, TelegramLoginPhase.signup);
    expect(cubit.state.signup, _info);
  });

  test('LOGIN_CODE_INVALID expires the flow', () async {
    final cubit = make();
    await cubit.start();
    exchange(_err('LOGIN_CODE_INVALID', status: 401));

    await cubit.check();

    expect(cubit.state.phase, TelegramLoginPhase.expired);
  });

  test('past the expiry time it expires without asking the server', () async {
    final cubit = make();
    await cubit.start();
    now = _expires.add(const Duration(seconds: 1));

    await cubit.check();

    expect(cubit.state.phase, TelegramLoginPhase.expired);
    verifyNever(
      () => repo.exchangeTelegramLogin(
        code: any(named: 'code'),
        codeVerifier: any(named: 'codeVerifier'),
      ),
    );
  });

  test('a network error keeps waiting and reports it once', () async {
    final cubit = make();
    await cubit.start();
    exchange(_err('NETWORK_ERROR', status: 0));

    await cubit.check();

    expect(cubit.state.phase, TelegramLoginPhase.waiting);
    expect(cubit.state.failure?.code, 'NETWORK_ERROR');
    expect(cubit.state.checking, isFalse);
  });

  group('signup', () {
    Future<TelegramLoginCubit> atSignup() async {
      final cubit = make();
      await cubit.start();
      exchange(const TelegramNeedsSignup(_info));
      await cubit.check();
      return cubit;
    }

    void stubSignup(Object answer) {
      final call = when(
        () => repo.signupWithTelegram(
          code: any(named: 'code'),
          codeVerifier: any(named: 'codeVerifier'),
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          currency: any(named: 'currency'),
        ),
      );
      if (answer is Exception) {
        call.thenThrow(answer);
      } else {
        call.thenAnswer((_) async => answer as ({User user, AuthToken token}));
      }
    }

    test('creates the account and signs in', () async {
      final cubit = await atSignup();
      stubSignup((user: _user, token: _token));

      await cubit.signup(
        displayName: 'Ann Lee',
        username: 'annlee',
        currency: 'THB',
      );

      expect(cubit.state.phase, TelegramLoginPhase.idle);
      verify(() => auth.signInWith(any())).called(1);
    });

    test('a taken username stays on the page with the free one', () async {
      final cubit = await atSignup();
      stubSignup(
        _err(
          'USERNAME_EXISTS',
          status: 409,
          d: {'username_suggestion': 'annlee2'},
        ),
      );

      await cubit.signup(
        displayName: 'Ann Lee',
        username: 'annlee',
        currency: 'THB',
      );

      expect(cubit.state.phase, TelegramLoginPhase.signup);
      expect(cubit.state.failure?.code, 'USERNAME_EXISTS');
      expect(cubit.state.signup?.usernameSuggestion, 'annlee2');
    });

    test('TELEGRAM_ALREADY_LINKED sends the user back to start', () async {
      final cubit = await atSignup();
      stubSignup(_err('TELEGRAM_ALREADY_LINKED', status: 409));

      await cubit.signup(
        displayName: 'Ann Lee',
        username: 'annlee',
        currency: 'THB',
      );

      expect(cubit.state.phase, TelegramLoginPhase.expired);
      expect(cubit.state.failure?.code, 'TELEGRAM_ALREADY_LINKED');
    });

    test('signup does nothing before the sign-up page is reached', () async {
      final cubit = make();
      await cubit.start();

      await cubit.signup(displayName: 'A', username: 'abc', currency: 'THB');

      verifyNever(
        () => repo.signupWithTelegram(
          code: any(named: 'code'),
          codeVerifier: any(named: 'codeVerifier'),
          displayName: any(named: 'displayName'),
          username: any(named: 'username'),
          currency: any(named: 'currency'),
        ),
      );
    });
  });

  test('reset forgets the code: a later check asks nothing', () async {
    final cubit = make();
    await cubit.start();

    cubit.reset();
    await cubit.check();

    expect(cubit.state.phase, TelegramLoginPhase.idle);
    verifyNever(
      () => repo.exchangeTelegramLogin(
        code: any(named: 'code'),
        codeVerifier: any(named: 'codeVerifier'),
      ),
    );
  });
}
