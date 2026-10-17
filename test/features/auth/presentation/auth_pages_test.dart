import 'dart:async';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/pages/login_page.dart';
import 'package:chubi_pocket/features/auth/presentation/pages/register_page.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/locale_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/theme_mode_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/theme_builder.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _MockTokens extends Mock implements SecureTokenStorage {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _FakeApi extends Fake implements ApiClient {
  final _c = StreamController<void>.broadcast();
  @override
  Stream<void> get onUnauthorized => _c.stream;
}

/// Login and Register are the Auth template + kit pieces only (owner
/// 2026-10-12): the page is an AuthPageBody, its fields are kit AppInputs, and
/// both follow the app theme (dark too).
void main() {
  late AuthCubit auth;
  late _MockRepo repo;
  late LocaleCubit locale;
  late ThemeModeCubit themeMode;
  late PendingCubit pendingCubit;
  late UnreadBadgeCubit unreadCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    locale = LocaleCubit(prefs);
    themeMode = ThemeModeCubit(prefs);
    final pending = _Pending();
    final unread = _Unread();
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    pendingCubit = pending;
    unreadCubit = unread;
    repo = _MockRepo();
    auth = AuthCubit(
      repository: repo,
      tokenStorage: _MockTokens(),
      apiClient: _FakeApi(),
    );
  });

  Future<void> pump(
    WidgetTester t,
    Widget page, {
    Brightness b = Brightness.light,
    bool offline = false,
  }) {
    final theme = ThemeBuilder.build(
      theme: ThemeRegistry.byId(ThemeRegistry.defaultThemeId),
      font: FontRegistry.inter,
      brightness: b,
    );
    return t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: locale),
          BlocProvider.value(value: themeMode),
          BlocProvider.value(value: pendingCubit),
          BlocProvider.value(value: unreadCubit),
        ],
        child: MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) => AppUiConfig(
            child: ConnectionScope(
              offline: offline,
              reconnects: 0,
              child: child!,
            ),
          ),
          home: page,
        ),
      ),
    );
  }

  testWidgets('login: AuthPageBody + 2 kit inputs + brand + prefs', (t) async {
    await pump(t, const LoginPage());
    expect(find.byType(AuthPageBody), findsOneWidget);
    expect(find.byType(AppInput), findsNWidgets(2));
    expect(find.byType(BrandHeader), findsOneWidget);
    expect(find.byType(LanguageThemeBar), findsOneWidget);
    expect(find.byType(OrDivider), findsOneWidget);
  });

  testWidgets('register: AuthPageBody + grouped kit fields', (t) async {
    await pump(t, const RegisterPage());
    expect(find.byType(AuthPageBody), findsOneWidget);
    expect(find.byType(SectionCard), findsNWidgets(2));
    expect(find.byType(AppInput), findsNWidgets(5));
  });

  // Offline mode (owner 2026-10-12): sign in / register can't reach the
  // server, so the submit button disables itself; what was typed stays.
  bool submitEnabled(WidgetTester t, String label) => t
      .widget<ButtonStyleButton>(
        find.descendant(
          of: find.widgetWithText(AppButton, label),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      )
      .enabled;

  testWidgets('offline: login submit disabled, typed input kept', (t) async {
    await pump(t, const LoginPage());
    expect(submitEnabled(t, 'Log in'), isTrue);
    await t.enterText(find.byType(TextField).first, 'alice');
    await pump(t, const LoginPage(), offline: true);
    expect(submitEnabled(t, 'Log in'), isFalse);
    expect(find.text('alice'), findsOneWidget);
    await pump(t, const LoginPage());
    expect(submitEnabled(t, 'Log in'), isTrue);
  });

  testWidgets('offline: register submit disabled', (t) async {
    await pump(t, const RegisterPage(), offline: true);
    expect(submitEnabled(t, 'Create account'), isFalse);
  });

  testWidgets('both pages take the app theme in dark mode', (t) async {
    await pump(t, const LoginPage(), b: Brightness.dark);
    final dark = Theme.of(
      t.element(find.byType(Scaffold)),
    ).scaffoldBackgroundColor;
    expect(t.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, isNull);
    expect(dark.computeLuminance(), lessThan(0.3));
    await pump(t, const RegisterPage(), b: Brightness.dark);
    final dark2 = Theme.of(
      t.element(find.byType(Scaffold)),
    ).scaffoldBackgroundColor;
    expect(t.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, isNull);
    expect(dark2.computeLuminance(), lessThan(0.3));
  });

  /// The login fails with [error] (the BE's answer).
  Future<void> failLogin(WidgetTester t, ApiException error) async {
    when(
      () => repo.login(
        identifier: any(named: 'identifier'),
        password: any(named: 'password'),
      ),
    ).thenThrow(error);
    await auth.login(identifier: 'ppond', password: 'nope');
    await t.pump();
  }

  const wrong = ApiException(
    code: 'INVALID_CREDENTIALS',
    message: 'Invalid credentials',
    statusCode: 401,
  );

  testWidgets('a wrong login: the words come from the central errors', (
    t,
  ) async {
    await pump(t, const LoginPage());
    await failLogin(t, wrong);
    expect(find.text('Username or password incorrect'), findsOneWidget);
    expect(find.text('Invalid credentials'), findsNothing);
  });

  testWidgets('an unknown code never shows the BE text', (t) async {
    await pump(t, const LoginPage());
    await failLogin(
      t,
      const ApiException(
        code: 'SOMETHING_NEW',
        message: 'raw english',
        statusCode: 400,
      ),
    );
    expect(find.text('raw english'), findsNothing);
    expect(
      find.text('Something we did not expect happened. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('register: a failed login left behind does not show', (t) async {
    await pump(t, const LoginPage());
    await failLogin(t, wrong);
    await pump(t, const RegisterPage());
    await t.pump();
    expect(auth.state, isNot(isA<AuthFailure>()));
    expect(find.text('Invalid credentials'), findsNothing);
    expect(find.text('Username or password incorrect'), findsNothing);
  });
}
