import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/data/sync_coordinator.dart';
import 'package:chubi_pocket/app/shell/shell_chrome.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/data/accounts_repository.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/font_id_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/locale_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/theme_id_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/theme_mode_cubit.dart';
import 'package:chubi_pocket/features/settings/presentation/pages/edit_profile_page.dart';
import 'package:chubi_pocket/features/settings/presentation/pages/settings_page.dart';
import 'package:chubi_pocket/features/users/data/users_repository.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../shared/fake_sync.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Users extends Mock implements UsersRepository {}

class _AccountsRepo extends Fake implements AccountsRepository {}

/// An [AuthCubit] that starts signed in and applies [updateUser] like the real
/// one; counts the pull-to-refresh style updates.
class _Auth extends Cubit<AuthState> implements AuthCubit {
  _Auth(User user) : super(AuthAuthenticated(user));

  @override
  void updateUser(User user) => emit(AuthAuthenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `GET /users/me` as prod answers (with `default_account` and
/// `auto_copy_own_event_bills`).
Map<String, dynamic> _meJson({
  String currency = 'THB',
  Map<String, dynamic>? defaultAccount = const {
    'id': 'w1',
    'name': 'Doraemon',
    'icon_code': {'icon': 'bank', 'color': 'blue'},
  },
  String? email = 'ppond@example.com',
}) => {
  'id': 'u1',
  'username': 'ppond',
  'email': email,
  'email_verified_at': null,
  'display_name': 'ppOnd',
  'currency': currency,
  'icon_code': null,
  'status': 'active',
  'default_account': defaultAccount,
  'auto_copy_own_event_bills': true,
  'notification_summary': {'on': 9, 'auto': 2},
  'preferences': {
    'timezone': null,
    'theme': null,
    'language': null,
    'fee_category_id': null,
  },
  'created_at': '2026-09-16T03:00:00Z',
  'updated_at': '2026-10-06T08:59:00Z',
};

Account _wallet(String id, String name) => Account.fromJson({
  'id': id,
  'name': name,
  'type': 'bank',
  'group': 'asset',
  'balance': 100.0,
  'currency': 'THB',
  'icon_code': {'icon': 'bank', 'color': 'blue'},
  'status': 'active',
  'sort_order': 0,
  'my_role': 'owner',
  'can_edit': true,
  'is_shared': false,
  'track_balance': true,
});

void main() {
  late _Users users;
  late _Auth auth;

  setUpAll(() {
    registerFallbackValue(const IconCode(icon: 'x'));
  });

  setUp(() {
    users = _Users();
    auth = _Auth(User.fromJson(_meJson()));
    // The pull / show refresh: the same profile again.
    when(() => users.getMe()).thenAnswer((_) async => User.fromJson(_meJson()));
  });

  Future<void> pump(WidgetTester t, Widget page) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    t.view.physicalSize = const Size(400, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final locale = LocaleCubit(prefs);
    final accounts = AccountsCubit(
      repository: _AccountsRepo(),
      coordinator: testCoordinator(),
    );
    addTearDown(accounts.close);
    addTearDown(auth.close);
    accounts.emit(
      AccountsState(
        accounts: [_wallet('w1', 'Doraemon'), _wallet('w2', 'Nobita')],
        status: AccountsStatus.loaded,
      ),
    );
    final pending = _Pending();
    final unread = _Unread();
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    await t.pumpWidget(
      RepositoryProvider<UsersRepository>.value(
        value: users,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<LocaleCubit>.value(value: locale),
            BlocProvider(create: (_) => ThemeModeCubit(prefs)),
            BlocProvider(create: (_) => ThemeIdCubit(prefs)),
            BlocProvider(create: (_) => FontIdCubit(prefs, locale)),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) =>
                RepositoryProvider<SyncCoordinator>.value(
                  value: testCoordinator(),
                  child: AppUiConfig(child: child!),
                ),
            home: Scaffold(
              body: ShellChrome(
                controller: ShellChromeController(),
                child: page,
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
  }

  test(
    'User parses the prod-shaped /users/me (default_account, auto copy)',
    () {
      final u = User.fromJson(_meJson());
      expect(u.defaultAccount?.id, 'w1');
      expect(u.defaultAccount?.name, 'Doraemon');
      expect(u.autoCopyOwnEventBills, isTrue);
      final none = User.fromJson(_meJson(defaultAccount: null));
      expect(none.defaultAccount, isNull);
      expect(u.notificationSummary?.on, 9);
      expect(u.notificationSummary?.auto, 2);
      final bare = Map<String, dynamic>.of(_meJson())
        ..remove('notification_summary');
      expect(User.fromJson(bare).notificationSummary, isNull);
    },
  );

  testWidgets('settings home shows the groups, the currency and main wallet', (
    t,
  ) async {
    await pump(t, const SettingsPage());
    expect(find.text('ppOnd'), findsOneWidget);
    expect(find.text('@ppond | ppond@example.com'), findsOneWidget);
    for (final s in ['App', 'Money', 'Data', 'About']) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.text('Main wallet'), findsOneWidget);
    expect(find.text('Doraemon'), findsOneWidget);
    // The notifications row shows the server's numbers.
    expect(find.text('9 on | 2 automatic'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('0.4'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('a failing refresh keeps the settings home on screen', (t) async {
    when(
      () => users.getMe(),
    ).thenThrow(const ApiException(code: 'X', message: 'x', statusCode: 500));
    await pump(t, const SettingsPage());
    await t.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await t.pumpAndSettle();
    expect(find.text('ppOnd'), findsOneWidget);
    expect(find.text('Main wallet'), findsOneWidget);
  });

  testWidgets('changing the currency sends ONE PUT after the warning', (
    t,
  ) async {
    when(
      () => users.updateMe(currency: 'USD'),
    ).thenAnswer((_) async => User.fromJson(_meJson(currency: 'USD')));
    await pump(t, const SettingsPage());
    await t.tap(find.text('Currency'));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('USD').first);
    await t.pumpAndSettle();
    // The "not converted" warning comes first; nothing is sent yet.
    verifyNever(() => users.updateMe(currency: any(named: 'currency')));
    await t.tap(find.text('Change currency'));
    await t.pumpAndSettle();
    verify(() => users.updateMe(currency: 'USD')).called(1);
    expect((auth.state as AuthAuthenticated).user.currency, 'USD');
  });

  testWidgets('money format: an option sends ONE PUT (money_style)', (t) async {
    when(() => users.setMoneyStyle('parentheses')).thenAnswer(
      (_) async => User.fromJson({
        ..._meJson(),
        'preferences': {'money_style': 'parentheses'},
      }),
    );
    await pump(t, const SettingsPage());
    // A user from before the setting: + / − in colour, the colour switch on.
    expect(find.text('Money format'), findsOneWidget);
    expect(find.text('Red / green colours'), findsOneWidget);
    await t.tap(find.text('Money format'));
    await t.pumpAndSettle();
    await t.tap(find.text('Parentheses ( )').last);
    await t.pumpAndSettle();
    verify(() => users.setMoneyStyle('parentheses')).called(1);
    expect((auth.state as AuthAuthenticated).user.moneyStyle, 'parentheses');
  });

  testWidgets('changing the main wallet sends ONE PUT', (t) async {
    when(
      () => users.updateMe(defaultAccountId: 'w2', clearDefaultAccount: false),
    ).thenAnswer(
      (_) async => User.fromJson(
        _meJson(defaultAccount: {'id': 'w2', 'name': 'Nobita'}),
      ),
    );
    await pump(t, const SettingsPage());
    await t.tap(find.text('Main wallet'));
    await t.pumpAndSettle();
    await t.tap(find.text('Nobita'));
    await t.pumpAndSettle();
    verify(
      () => users.updateMe(defaultAccountId: 'w2', clearDefaultAccount: false),
    ).called(1);
    expect(
      (auth.state as AuthAuthenticated).user.defaultAccount?.name,
      'Nobita',
    );
  });

  testWidgets('profile view: card, email, security; no currency', (t) async {
    await pump(t, const EditProfilePage());
    expect(find.text('ppOnd'), findsOneWidget);
    expect(find.text('@ppond'), findsWidgets);
    expect(find.text('ppond@example.com'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Currency'), findsNothing);
  });

  testWidgets(
    'profile edit hides username and password; saving sends one PUT',
    (t) async {
      when(
        () => users.updateMe(
          displayName: any(named: 'displayName'),
          email: any(named: 'email'),
          iconCode: any(named: 'iconCode'),
          clearIconCode: any(named: 'clearIconCode'),
        ),
      ).thenAnswer((_) async {
        final j = _meJson()..['display_name'] = 'Pond';
        return User.fromJson(j);
      });
      await pump(t, const EditProfilePage());
      await t.tap(find.byIcon(AppIcons.edit));
      await t.pumpAndSettle();
      expect(find.text('Security'), findsNothing);
      expect(find.text('Change password'), findsNothing);
      await t.enterText(find.byType(EditableText).first, 'Pond');
      await t.pump();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      verify(
        () => users.updateMe(
          displayName: 'Pond',
          email: null,
          iconCode: null,
          clearIconCode: false,
        ),
      ).called(1);
      expect((auth.state as AuthAuthenticated).user.displayName, 'Pond');
    },
  );
}
