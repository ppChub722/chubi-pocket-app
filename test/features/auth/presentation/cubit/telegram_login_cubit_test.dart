import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/auth/data/telegram_oidc.dart';
import 'package:chubi_pocket/features/auth/domain/auth_token.dart';
import 'package:chubi_pocket/features/auth/domain/telegram_login.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/telegram_login_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _MockAuth extends Mock implements AuthCubit {}

class _MockOidc extends Mock implements TelegramOidc {}

const _user = User(
  id: 'u-1',
  username: 'alice',
  displayName: 'Alice',
  currency: 'THB',
);
const _token = AuthToken(accessToken: 'tok', expiresIn: 2592000);
const _login = TelegramTokenLogin(user: _user, token: _token, isNew: false);

ApiException _err(String code, {int status = 400}) =>
    ApiException(code: code, message: code, statusCode: status);

void main() {
  late _MockRepo repo;
  late _MockAuth auth;
  late _MockOidc oidc;

  TelegramLoginCubit make() =>
      TelegramLoginCubit(repository: repo, auth: auth, oidc: oidc);

  setUpAll(() {
    registerFallbackValue((user: _user, token: _token));
    registerFallbackValue(TelegramOidcPurpose.login);
  });

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    oidc = _MockOidc();
    when(() => auth.signInWith(any())).thenAnswer((_) async {});
    when(() => repo.telegramLogin(any())).thenAnswer((_) async => _login);
  });

  test('Telegram id_token → POST /auth/telegram/token → signed in', () async {
    when(
      () => oidc.signIn(TelegramOidcPurpose.login),
    ).thenAnswer((_) async => 'jwt');
    final c = make();

    await c.signIn();

    verify(() => repo.telegramLogin('jwt')).called(1);
    final signed =
        verify(() => auth.signInWith(captureAny())).captured.single
            as ({User user, AuthToken token});
    expect(signed.token.accessToken, 'tok');
    expect(c.state.busy, isFalse);
    expect(c.state.failure, isNull);
  });

  test('no redirect back (cancelled / timed out) → idle, no call', () async {
    when(() => oidc.signIn(any())).thenAnswer((_) async => null);
    final c = make();

    await c.signIn();

    verifyNever(() => repo.telegramLogin(any()));
    expect(c.state.busy, isFalse);
    expect(c.state.failure, isNull);
  });

  test('Telegram could not be opened → openFailed', () async {
    when(() => oidc.signIn(any())).thenThrow(const TelegramOidcOpenFailed());
    final c = make();

    await c.signIn();

    expect(c.state.openFailed, isTrue);
    expect(c.state.failureId, 1);
  });

  test('the BE refuses the token → failure shown once', () async {
    when(() => oidc.signIn(any())).thenAnswer((_) async => 'jwt');
    when(
      () => repo.telegramLogin(any()),
    ).thenThrow(_err('TELEGRAM_TOKEN_INVALID', status: 401));
    final c = make();

    await c.signIn();

    expect(c.state.failure?.code, 'TELEGRAM_TOKEN_INVALID');
    expect(c.state.failureId, 1);
    verifyNever(() => auth.signInWith(any()));
  });

  test('a login redirect that came back after the app was killed', () async {
    when(() => oidc.resume()).thenAnswer(
      (_) async => (purpose: TelegramOidcPurpose.login, token: 'jwt'),
    );
    final c = make();

    await c.resumePending();

    verify(() => repo.telegramLogin('jwt')).called(1);
    verify(() => auth.signInWith(any())).called(1);
  });

  test('a pending link redirect is not a login', () async {
    when(() => oidc.resume()).thenAnswer(
      (_) async => (purpose: TelegramOidcPurpose.link, token: 'jwt'),
    );
    final c = make();

    await c.resumePending();

    verifyNever(() => repo.telegramLogin(any()));
  });
}
