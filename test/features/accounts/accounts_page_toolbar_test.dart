import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/shell_chrome.dart';
import 'package:chubi_pocket/features/accounts/data/accounts_repository.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/accounts/presentation/pages/accounts_page.dart';
import 'package:chubi_pocket/features/accounts/presentation/widgets/account_card.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Repo extends Fake implements AccountsRepository {}

Account _wallet(String id, String name, int order) => Account.fromJson({
  'id': id,
  'name': name,
  'type': 'bank',
  'group': 'asset',
  'balance': 100.0,
  'currency': 'THB',
  'icon_code': {'icon': 'bank', 'color': 'blue'},
  'status': 'active',
  'sort_order': order,
  'my_role': 'owner',
  'can_edit': true,
  'is_shared': false,
  'track_balance': true,
});

void main() {
  setUp(ToolbarToggleState.resetAll);

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(400, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final cubit = AccountsCubit(repository: _Repo());
    addTearDown(cubit.close);
    cubit.emit(
      AccountsState(
        accounts: [_wallet('w1', 'KBank', 0), _wallet('w2', 'Cash', 1)],
        status: AccountsStatus.loaded,
      ),
    );
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountsCubit>.value(value: cubit),
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<PendingCubit>.value(value: pending),
          BlocProvider<UnreadBadgeCubit>.value(value: unread),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) => AppUiConfig(child: child!),
          home: ShellChrome(
            controller: ShellChromeController(),
            child: const AccountsPage(),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  CardActionButton dotButton(WidgetTester t) => t.widget(
    find.descendant(
      of: find.byType(ToolbarToggleButton),
      matching: find.byType(CardActionButton),
    ),
  );

  testWidgets('🔍 in the card; toolbar hidden; search filters by name; dot', (
    t,
  ) async {
    await pump(t);
    expect(find.byType(ToolbarToggleButton), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(AccountCard), findsNWidgets(2));
    expect(dotButton(t).showDot, isFalse);

    await t.tap(find.byType(ToolbarToggleButton));
    await t.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await t.enterText(find.byType(TextField), 'cash');
    await t.pumpAndSettle();
    expect(find.byType(AccountCard), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);

    await t.tap(find.byType(ToolbarToggleButton));
    await t.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(dotButton(t).showDot, isTrue);
    // Still filtered while hidden.
    expect(find.byType(AccountCard), findsOneWidget);
  });

  testWidgets('a non-default sort puts the dot on the hidden 🔍', (t) async {
    await pump(t);
    await t.tap(find.byType(ToolbarToggleButton));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(AppChip, 'My order'));
    await t.pumpAndSettle();
    await t.tap(find.text('Name').last);
    await t.pumpAndSettle();
    await t.tap(find.byType(ToolbarToggleButton));
    await t.pumpAndSettle();
    expect(dotButton(t).showDot, isTrue);
  });
}
