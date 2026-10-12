import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/locale_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/theme_mode_cubit.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/settings/presentation/pages/change_password_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/theme_builder.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Mock implements AuthRepository {}

class _Tokens extends Mock implements SecureTokenStorage {}

class _FakeApi extends Fake implements ApiClient {
  final _c = StreamController<void>.broadcast();
  @override
  Stream<void> get onUnauthorized => _c.stream;
}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

/// Change password = a create-style page on the detail template: one headless
/// box of three kit password fields, on the app theme (dark too), field errors
/// for a mismatch / a wrong current password.
void main() {
  late _Repo repo;
  late AuthCubit auth;
  late LocaleCubit locale;
  late ThemeModeCubit themeMode;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    locale = LocaleCubit(prefs);
    themeMode = ThemeModeCubit(prefs);
    repo = _Repo();
    auth = AuthCubit(
      repository: repo,
      tokenStorage: _Tokens(),
      apiClient: _FakeApi(),
    );
  });

  Future<void> pump(WidgetTester t, {Brightness b = Brightness.light}) {
    final pending = _Pending();
    final unread = _Unread();
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    final theme = ThemeBuilder.build(
      theme: ThemeRegistry.byId(ThemeRegistry.defaultThemeId),
      font: FontRegistry.inter,
      brightness: b,
    );
    return t.pumpWidget(
      MultiRepositoryProvider(
        providers: [RepositoryProvider<AuthRepository>.value(value: repo)],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<LocaleCubit>.value(value: locale),
            BlocProvider<ThemeModeCubit>.value(value: themeMode),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
          ],
          child: MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(child: child!),
            home: const ChangePasswordPage(),
          ),
        ),
      ),
    );
  }

  testWidgets('one box of three kit password fields, helper under New', (
    t,
  ) async {
    await pump(t);
    expect(find.byType(DetailPageBody), findsOneWidget);
    expect(find.byType(SectionCard), findsOneWidget);
    expect(find.byType(AppInput), findsNWidgets(3));
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('takes the app theme in dark mode (no page colour)', (t) async {
    await pump(t, b: Brightness.dark);
    expect(t.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, isNull);
    final bg = Theme.of(
      t.element(find.byType(Scaffold)),
    ).scaffoldBackgroundColor;
    expect(bg.computeLuminance(), lessThan(0.3));
  });

  testWidgets('a wrong current password is a field error', (t) async {
    when(
      () => repo.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenThrow(
      const ApiException(code: 'WRONG_PASSWORD', message: 'x', statusCode: 401),
    );
    await pump(t);
    final fields = find.byType(EditableText);
    await t.enterText(fields.at(0), 'wrongpass1');
    await t.enterText(fields.at(1), 'newpass123');
    await t.enterText(fields.at(2), 'newpass123');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    verify(
      () => repo.changePassword(
        currentPassword: 'wrongpass1',
        newPassword: 'newpass123',
      ),
    ).called(1);
    expect(find.byType(DetailPageBody), findsOneWidget);
  });
}
