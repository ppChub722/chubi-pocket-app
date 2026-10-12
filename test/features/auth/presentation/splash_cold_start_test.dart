import 'dart:async';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/pages/splash_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements AuthRepository {}

class _Tokens extends Mock implements SecureTokenStorage {}

class _Api extends Fake implements ApiClient {
  final _c = StreamController<void>.broadcast();
  @override
  Stream<void> get onUnauthorized => _c.stream;
}

const _user = User(
  id: 'u-1',
  username: 'alice',
  displayName: 'Alice',
  currency: 'THB',
);

/// Cold start with the server unreachable (owner 2026-10-12, offline mode):
/// the splash is the ONE full-screen error + retry (the stored token is
/// kept), and it re-runs the check by itself when the connection comes back.
void main() {
  late _Repo repo;
  late _Tokens tokens;
  late AuthCubit auth;
  var down = true;

  setUp(() {
    repo = _Repo();
    tokens = _Tokens();
    down = true;
    when(() => tokens.readAuthToken()).thenAnswer((_) async => 'tok');
    when(() => repo.getCurrentUser()).thenAnswer((_) async {
      if (down) {
        throw const ApiException(code: 'NETWORK_ERROR', message: 'no net');
      }
      return _user;
    });
    auth = AuthCubit(repository: repo, tokenStorage: tokens, apiClient: _Api());
  });

  tearDown(() => auth.close());

  Widget app({required int reconnects}) => BlocProvider<AuthCubit>.value(
    value: auth,
    child: MaterialApp(
      theme: ThemeData(
        extensions: [
          ThemeRegistry.byId(
            ThemeRegistry.defaultThemeId,
          ).colorsFor(Brightness.light),
        ],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) => AppUiConfig(
        child: ConnectionScope(
          offline: reconnects == 0,
          reconnects: reconnects,
          child: child!,
        ),
      ),
      home: const SplashPage(),
    ),
  );

  testWidgets('offline cold start: full-screen error + retry, token kept', (
    t,
  ) async {
    await t.pumpWidget(app(reconnects: 0));
    await t.pump(const Duration(milliseconds: 700));
    expect(auth.state, isA<AuthInitial>());
    expect((auth.state as AuthInitial).startupError, isNotNull);
    expect(find.byType(ErrorView), findsOneWidget);
    verifyNever(() => tokens.clearAuthToken());
  });

  testWidgets('the connection coming back re-runs the check by itself', (
    t,
  ) async {
    await t.pumpWidget(app(reconnects: 0));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.byType(ErrorView), findsOneWidget);
    down = false;
    await t.pumpWidget(app(reconnects: 1));
    await t.pump();
    await t.pump();
    expect(auth.state, const AuthAuthenticated(_user));
    verify(() => repo.getCurrentUser()).called(2);
  });

  testWidgets('init calls while one runs join it (one /me)', (t) async {
    down = false;
    await Future.wait([auth.init(), auth.init()]);
    expect(auth.state, const AuthAuthenticated(_user));
    verify(() => repo.getCurrentUser()).called(1);
  });
}
