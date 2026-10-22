import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/fade_branch_container.dart';
import 'package:chubi_pocket/app/shell/main_shell.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/domain/account_type.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/pages/pending_page.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/theme_builder.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../shared/fake_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Repo extends Fake implements TransactionsRepository {}

const _wallet = Account(
  id: 'w1',
  name: 'KBank',
  type: AccountType.bank,
  currency: 'THB',
  balance: 0,
);

/// A page that offers [preset] to the +, with buttons to push / pop.
Widget _page(String name, {QuickCreatePreset? preset}) {
  final body = Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 80),
          Text('page $name'),
          TextButton(
            onPressed: () => context.push('/a/debts'),
            child: const Text('to debts'),
          ),
          TextButton(
            onPressed: () => context.push('/a/plain'),
            child: const Text('to plain'),
          ),
          TextButton(
            onPressed: () => context.push('/a/wallet'),
            child: const Text('to wallet'),
          ),
        ],
      ),
    ),
  );
  return preset == null
      ? body
      : QuickCreatePresetScope(preset: preset, child: body);
}

String _root(ShellTab tab) => switch (tab) {
  ShellTab.home => '/a',
  ShellTab.transactions => '/b',
  ShellTab.accounts => '/c',
  ShellTab.more => '/d',
  _ => '/${tab.name}',
};

/// The real shell (MainShell → MainBottomNav → QuickCreateButton) over stub
/// pages, the route observers as in app_router.dart, and the REAL pending
/// page on its tab.
GoRouter _router() => GoRouter(
  initialLocation: '/a',
  routes: [
    StatefulShellRoute(
      navigatorContainerBuilder: (context, navigationShell, children) =>
          FadeBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        for (final tab in ShellTab.values)
          StatefulShellBranch(
            observers: [QuickCreateRouteObserver()],
            routes: [
              GoRoute(
                path: _root(tab),
                builder: (_, _) => tab == ShellTab.pending
                    ? const PendingPage()
                    : _page(tab.name),
              ),
              if (tab == ShellTab.home) ...[
                GoRoute(
                  path: '/a/debts',
                  builder: (_, _) => _page(
                    'debts',
                    preset: const QuickCreatePreset.debt(
                      person: EmbeddedPerson(name: 'Mom', contactId: 'c1'),
                    ),
                  ),
                ),
                GoRoute(path: '/a/plain', builder: (_, _) => _page('plain')),
                GoRoute(
                  path: '/a/wallet',
                  builder: (_, _) => _page(
                    'wallet',
                    preset: const QuickCreatePreset(account: _wallet),
                  ),
                ),
              ],
            ],
          ),
      ],
    ),
  ],
);

void main() {
  late GoRouter router;

  Future<void> pump(WidgetTester t) async {
    SharedPreferences.setMockInitialValues({});
    final accounts = _Accounts();
    final categories = _Categories();
    final tags = _Tags();
    final txs = _Txs();
    final pending = _Pending();
    final unread = _Unread();
    final auth = _Auth();
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => tags.state).thenReturn(const TagsState());
    when(() => txs.state).thenReturn(const TransactionsState());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => tags.loadIfNeeded()).thenAnswer((_) async {});
    when(() => pending.load()).thenAnswer((_) async {});
    router = _router();
    await t.pumpWidget(
      RepositoryProvider<TransactionsRepository>.value(
        value: _Repo(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<TransactionsCubit>.value(value: txs),
            FakeTxFormOptions().provider,
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<AuthCubit>.value(value: auth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeBuilder.build(
              theme: ThemeRegistry.byId(ThemeRegistry.defaultThemeId),
              font: FontRegistry.inter,
              brightness: Brightness.light,
            ),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => AppUiConfig(child: child!),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  QuickCreateMode mode(WidgetTester t) =>
      t.widget<QuickCreateButton>(find.byType(QuickCreateButton)).mode;

  /// The + fill as drawn (after its colour animation).
  Color fill(WidgetTester t) => t
      .widget<Material>(
        find.descendant(
          of: find.byType(QuickCreateButton),
          matching: find.byType(Material),
        ),
      )
      .color!;

  Color colorOf(WidgetTester t, QuickCreateMode m) =>
      QuickCreateModeColors.of(t.element(find.byType(QuickCreateButton)), m);

  Future<void> tapText(WidgetTester t, String text) async {
    await t.tap(find.text(text).hitTestable());
    await t.pumpAndSettle();
  }

  testWidgets('the mode colours differ (tx = primary, debt purple, saving '
      'blue; owner 2026-10-22)', (t) async {
    await pump(t);
    final ctx = t.element(find.byType(QuickCreateButton));
    expect(colorOf(t, QuickCreateMode.tx), Theme.of(ctx).colorScheme.primary);
    expect(colorOf(t, QuickCreateMode.debt), const Color(0xFF7A5AE0));
    expect(colorOf(t, QuickCreateMode.saving), const Color(0xFF3B7DD8));
    expect(
      colorOf(t, QuickCreateMode.debt),
      isNot(colorOf(t, QuickCreateMode.tx)),
    );
  });

  testWidgets('the centre button is the capsule with the mode word', (t) async {
    await pump(t);
    final b = t.widget<QuickCreateButton>(find.byType(QuickCreateButton));
    expect(b.label, isNotNull);
    expect(
      t.getSize(find.byType(QuickCreateButton)).height,
      QuickCreateButton.capsuleHeight,
    );
    expect(find.byKey(const ValueKey('quickCreateLabel')), findsOneWidget);
  });

  testWidgets('a page with no preset: tx mode, primary', (t) async {
    await pump(t);
    expect(mode(t), QuickCreateMode.tx);
    expect(fill(t), colorOf(t, QuickCreateMode.tx));
  });

  testWidgets('push a debt page → debt colour; pop → tx restores', (t) async {
    await pump(t);
    await tapText(t, 'to debts');
    expect(mode(t), QuickCreateMode.debt);
    expect(fill(t), colorOf(t, QuickCreateMode.debt));
    router.pop();
    await t.pumpAndSettle();
    expect(find.text('page home').hitTestable(), findsOneWidget);
    expect(mode(t), QuickCreateMode.tx);
    expect(fill(t), colorOf(t, QuickCreateMode.tx));
  });

  testWidgets('the colour change is animated (~200 ms), not a snap', (t) async {
    await pump(t);
    await t.tap(find.text('to debts').hitTestable());
    await t.pumpAndSettle();
    router.pop();
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    final mid = fill(t);
    expect(mid, isNot(colorOf(t, QuickCreateMode.tx)));
    expect(mid, isNot(colorOf(t, QuickCreateMode.debt)));
    await t.pumpAndSettle();
    expect(fill(t), colorOf(t, QuickCreateMode.tx));
  });

  testWidgets('a page without a preset over a debt page → tx; back → debt', (
    t,
  ) async {
    await pump(t);
    await tapText(t, 'to debts');
    await tapText(t, 'to plain');
    expect(mode(t), QuickCreateMode.tx);
    router.pop();
    await t.pumpAndSettle();
    expect(mode(t), QuickCreateMode.debt);
  });

  testWidgets('tab switch: another tab → tx; back to the tab → debt', (
    t,
  ) async {
    await pump(t);
    await tapText(t, 'to debts');
    expect(mode(t), QuickCreateMode.debt);
    router.go('/b');
    await t.pumpAndSettle();
    expect(mode(t), QuickCreateMode.tx);
    router.go('/a/debts');
    await t.pumpAndSettle();
    expect(mode(t), QuickCreateMode.debt);
  });

  testWidgets('a wallet preset is tx mode (its colour), presets the wallet', (
    t,
  ) async {
    await pump(t);
    await tapText(t, 'to wallet');
    expect(mode(t), QuickCreateMode.tx);
    final shell = t.element(find.byType(QuickCreateButton));
    expect(
      QuickCreateContextScope.maybeOf(shell)?.preset,
      const QuickCreatePreset(account: _wallet),
    );
  });

  testWidgets('pending: the + opens the quick create (tx), not /pending/new', (
    t,
  ) async {
    await pump(t);
    router.go('/pending');
    await t.pumpAndSettle();
    expect(find.byType(PendingPage), findsOneWidget);
    expect(mode(t), QuickCreateMode.tx);
    await t.tap(find.byType(QuickCreateButton));
    await t.pumpAndSettle();
    expect(find.byType(QuickCreateSheetShell), findsOneWidget);
    expect(router.state.uri.path, '/pending');
  });
}
