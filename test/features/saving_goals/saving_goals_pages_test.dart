import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/data/saving_goals_repository.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goals_overview.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/pages/saving_goal_detail_page.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/pages/saving_goals_list_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'saving_goal_parse_test.dart' show prodDetail, prodList;

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Tx extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

/// Runs the REAL model parsing on prod-shaped JSON, or fails like the network.
class _Repo extends Fake implements SavingGoalsRepository {
  bool networkDown = false;
  int listCalls = 0;
  int detailCalls = 0;

  void _check() {
    if (networkDown) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no connection');
    }
  }

  @override
  Future<SavingGoalsOverview> list({String status = 'active'}) async {
    listCalls++;
    _check();
    return SavingGoalsOverview.fromJson(prodList());
  }

  @override
  Future<SavingGoalDetail> detail(String id) async {
    detailCalls++;
    _check();
    return SavingGoalDetail.fromJson(prodDetail());
  }
}

void main() {
  late _Repo repo;
  late QuickCreateContext registry;
  late StreamController<TransactionsState> txBook;

  setUp(() {
    ToolbarToggleState.resetAll();
    repo = _Repo();
    registry = QuickCreateContext();
    txBook = StreamController<TransactionsState>.broadcast();
  });

  tearDown(() {
    registry.dispose();
    txBook.close();
  });

  Future<void> pump(WidgetTester t, Widget home) async {
    // Tall view: the page is a lazy ListView.
    t.view.physicalSize = const Size(800, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final tx = _Tx();
    whenListen(tx, txBook.stream, initialState: const TransactionsState());
    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: 'u1', username: 'me', displayName: 'Me', currency: 'USD'),
      ),
    );
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    await t.pumpWidget(
      RepositoryProvider<SavingGoalsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<TransactionsCubit>.value(value: tx),
            BlocProvider<SavingGoalsCubit>(
              create: (_) => SavingGoalsCubit(repository: repo),
            ),
          ],
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
              child: QuickCreateContextScope(registry: registry, child: child!),
            ),
            home: home,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('list: prod-shaped JSON shows the totals, spare and the goal', (
    t,
  ) async {
    await pump(t, const SavingGoalsListPage());
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
    expect(find.text('Not allocated'), findsWidgets);
    expect(find.text('Saved in total'), findsOneWidget);
    expect(repo.listCalls, 1);
  });

  testWidgets(
    'list: summary card is inset, precedes the toolbar, spare first',
    (t) async {
      await pump(t, const SavingGoalsListPage());
      final card = find.ancestor(
        of: find.text('Saved in total'),
        matching: find.byType(AppCard),
      );
      expect(card, findsOneWidget);
      // Inset from the screen edge: the card (and its first value) is not
      // flush left, so nothing is clipped.
      expect(
        t
            .getTopLeft(
              find.descendant(of: card, matching: find.byType(Material)).first,
            )
            .dx,
        AppSpacing.lg,
      );
      expect(
        t.getTopLeft(find.text('Saved in total')).dx,
        greaterThanOrEqualTo(AppSpacing.lg * 2),
      );
      final toolbar = find.byType(ListToolbar);
      expect(toolbar, findsOneWidget);
      expect(t.getTopLeft(card).dy, lessThan(t.getTopLeft(toolbar).dy));
      // The toolbar is hidden until the card's search button is tapped.
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.descendant(of: card, matching: find.byIcon(AppIcons.search)));
      await t.pumpAndSettle();
      // Search field is there; the FIRST row is "not allocated", then the goal.
      expect(find.text('Search goals'), findsWidgets);
      final spare = t.getTopLeft(find.widgetWithText(ListRow, 'Not allocated'));
      final goal = t.getTopLeft(find.widgetWithText(ListRow, 'ทริปญี่ปุ่น'));
      expect(spare.dy, lessThan(goal.dy));
      expect(
        find.descendant(
          of: find.widgetWithText(ListRow, 'Not allocated'),
          matching: find.byType(IconTile),
        ),
        findsOneWidget,
      );
      // Local search by name.
      await t.enterText(find.byType(TextField), 'zzz');
      await t.pump();
      expect(find.text('ทริปญี่ปุ่น'), findsNothing);
    },
  );

  testWidgets('list: red dot when hidden with a search; status dropdown', (
    t,
  ) async {
    await pump(t, const SavingGoalsListPage());
    final btn = find.byType(ToolbarToggleButton);
    expect(btn, findsOneWidget);
    CardActionButton button() => t.widget<CardActionButton>(
      find.descendant(of: btn, matching: find.byType(CardActionButton)),
    );
    expect(button().showDot, isFalse);
    await t.tap(btn);
    await t.pumpAndSettle();
    expect(find.text('Status: Saving'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'zzz');
    await t.pump();
    await t.tap(btn);
    await t.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(button().showDot, isTrue);
    await t.tap(btn);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '');
    await t.tap(find.text('Status: Saving'));
    await t.pumpAndSettle();
    await t.tap(find.text('Reached').last);
    await t.pumpAndSettle();
    expect(find.text('Status: Reached'), findsOneWidget);
    expect(repo.listCalls, greaterThan(1));
    await t.tap(btn);
    await t.pumpAndSettle();
    expect(button().showDot, isTrue);
  });

  testWidgets('list: a failed first load is a full-page error', (t) async {
    repo.networkDown = true;
    await pump(t, const SavingGoalsListPage());
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('ทริปญี่ปุ่น'), findsNothing);
  });

  testWidgets('detail: ONE call on open; shows by-wallet and entries', (
    t,
  ) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(repo.detailCalls, 1);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('ทริปญี่ปุ่น'), findsWidgets);
    expect(find.text('กสิกร'), findsWidgets);
    expect(find.text('Saving entries'), findsOneWidget);
  });

  testWidgets('detail: a failed load is a full-page error', (t) async {
    repo.networkDown = true;
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(find.byType(ErrorView), findsOneWidget);
  });

  testWidgets('list: amounts use the user currency, not the row one', (
    t,
  ) async {
    await pump(t, const SavingGoalsListPage());
    expect(find.textContaining('฿'), findsNothing);
    expect(find.textContaining(r'$'), findsWidgets);
  });

  testWidgets('list: a transaction write or a saving elsewhere reloads', (
    t,
  ) async {
    await pump(t, const SavingGoalsListPage());
    expect(repo.listCalls, 1);
    txBook.add(const TransactionsState(revision: 1));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(repo.listCalls, 2);
    final ctx = t.element(find.byType(SavingGoalsListPage));
    ctx.read<SavingGoalsCubit>().markStale();
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(repo.listCalls, 3);
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
  });

  testWidgets('detail: amounts use the user currency', (t) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(find.textContaining('฿'), findsNothing);
    expect(find.textContaining(r'$'), findsWidgets);
  });

  testWidgets('detail: a transaction write or a saving elsewhere reloads', (
    t,
  ) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(repo.detailCalls, 1);
    txBook.add(const TransactionsState(revision: 1));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(repo.detailCalls, 2);
    final ctx = t.element(find.byType(SavingGoalDetailPage));
    ctx.read<SavingGoalsCubit>().markStale();
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(repo.detailCalls, 3);
    expect(find.byType(ErrorView), findsNothing);
  });
}
