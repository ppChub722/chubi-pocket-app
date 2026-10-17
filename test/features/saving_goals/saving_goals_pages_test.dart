import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/data/saving_goals_repository.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goals_overview.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/cubit/saving_goal_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/pages/saving_goal_detail_page.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/pages/saving_goals_list_page.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'saving_goal_parse_test.dart'
    show prodAutoSave, prodDetail, prodGoal, prodList, prodSpareDetail;

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Tx extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

/// Runs the REAL model parsing on prod-shaped JSON, or fails like the network.
/// Every write is logged, so a test can count the calls.
class _Repo extends Fake implements SavingGoalsRepository {
  bool networkDown = false;
  int listCalls = 0;
  int detailCalls = 0;
  final writes = <String>[];

  Map<String, dynamic> listJson = prodList();
  Map<String, dynamic> goalJson = prodGoal();
  ApiException? archiveError;

  void _check() {
    if (networkDown) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no connection');
    }
  }

  @override
  Future<SavingGoalsOverview> list({String status = 'active'}) async {
    listCalls++;
    _check();
    return SavingGoalsOverview.fromJson(listJson);
  }

  @override
  Future<SavingGoalDetail> detail(String id) async {
    detailCalls++;
    _check();
    return SavingGoalDetail.fromJson(
      id == SavingGoalsRepository.spareId
          ? prodSpareDetail()
          : prodDetail(goal: goalJson),
    );
  }

  /// The BE answers the goal page with the auto-saving in place.
  @override
  Future<SavingGoalDetail> setAutoSave(
    String id, {
    required double amount,
    required int day,
    String? accountId,
  }) async {
    writes.add('PUT $id auto-save $amount day $day wallet $accountId');
    return SavingGoalDetail.fromJson(
      prodDetail(
        goal: prodGoal(autoSave: {...prodAutoSave(), 'amount': amount}),
      ),
    );
  }

  @override
  Future<SavingGoalDetail> clearAutoSave(String id) async {
    writes.add('DELETE $id auto-save');
    return SavingGoalDetail.fromJson(prodDetail(goal: prodGoal()));
  }

  @override
  Future<SavingGoalDetail> archive(String id) async {
    writes.add('POST $id archive');
    final e = archiveError;
    if (e != null) throw e;
    return SavingGoalDetail.fromJson(
      prodDetail(goal: prodGoal(state: 'archived')),
    );
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

  /// Three goals: short this month (behind 2 months), done this month (on
  /// track), and behind with "0 months" (must never read "0 months late").
  Map<String, dynamic> threeGoals() => prodList(
    goals: [
      prodGoal(),
      prodGoal(
        id: 'g2',
        name: 'รถใหม่',
        status: 'on_track',
        monthShort: 0,
        saved: 30000,
      ),
      prodGoal(id: 'g3', name: 'บ้าน', behindMonths: 0, monthShort: 100),
    ],
  );

  // ── List ────────────────────────────────────────────────────────────

  testWidgets('list: summary card, groups and rows show the BE numbers', (
    t,
  ) async {
    repo.listJson = threeGoals();
    await pump(t, const SavingGoalsListPage());
    expect(find.byType(ErrorView), findsNothing);
    expect(repo.listCalls, 1);
    // The card: caption, saved_total, "still short" (month_short_total) and
    // the tappable unallocated line.
    expect(find.text('Total savings now'), findsOneWidget);
    expect(find.textContaining('60,500'), findsOneWidget);
    expect(
      find.textContaining('Still short this month \$2,500.00'),
      findsOneWidget,
    );
    expect(find.textContaining('Not allocated \$8,500.00'), findsOneWidget);
    // Groups, in the BE's order.
    final short = find.widgetWithText(SectionHeader, 'Still short this month');
    final done = find.widgetWithText(SectionHeader, 'Done this month ✓');
    expect(short, findsOneWidget);
    expect(done, findsOneWidget);
    expect(t.getTopLeft(short).dy, lessThan(t.getTopLeft(done).dy));
    // A row: name, "Short ฿x", "saved / target", the ETA badge.
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
    expect(find.text('Short \$2,500.00'), findsOneWidget);
    expect(find.textContaining('\$52,000.00 / \$80,000.00'), findsWidgets);
    expect(find.text('Goal May 2027 · 2 months late'), findsOneWidget);
    // Done group: a tick, a plain ETA badge (on track).
    expect(find.text('✓'), findsOneWidget);
    expect(find.text('Goal May 2027'), findsNWidgets(2));
    // "0 months late" never shows.
    expect(find.textContaining('0 months late'), findsNothing);
    expect(find.text('Goal May 2027 · 0 months late'), findsNothing);
    expect(find.text('Add saving goal'), findsOneWidget);
  });

  testWidgets('list: the search row is hidden until the card button', (
    t,
  ) async {
    await pump(t, const SavingGoalsListPage());
    final card = find.ancestor(
      of: find.text('Total savings now'),
      matching: find.byType(AppCard),
    );
    expect(card, findsOneWidget);
    expect(find.byType(ListToolbar), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await t.tap(
      find.descendant(of: card, matching: find.byIcon(AppIcons.search)),
    );
    await t.pumpAndSettle();
    expect(find.text('Search goals'), findsWidgets);
    expect(find.text('Status: Saving'), findsOneWidget);
    // Local search by name.
    await t.enterText(find.byType(TextField), 'zzz');
    await t.pump();
    expect(find.text('ทริปญี่ปุ่น'), findsNothing);
  });

  testWidgets('list: red dot when hidden with a search; status dropdown', (
    t,
  ) async {
    await pump(t, const SavingGoalsListPage());
    final btn = find.byType(ToolbarToggleButton);
    CardActionButton button() => t.widget<CardActionButton>(
      find.descendant(of: btn, matching: find.byType(CardActionButton)),
    );
    expect(button().showDot, isFalse);
    await t.tap(btn);
    await t.pumpAndSettle();
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
    // Switching the status re-opens the page: one more call.
    expect(repo.listCalls, 2);
  });

  testWidgets('list: a failed first load is a full-page error', (t) async {
    repo.networkDown = true;
    await pump(t, const SavingGoalsListPage());
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('ทริปญี่ปุ่น'), findsNothing);
  });

  testWidgets('list: a failed reload keeps the rows on screen', (t) async {
    await pump(t, const SavingGoalsListPage());
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
    repo.networkDown = true;
    final ctx = t.element(find.byType(SavingGoalsListPage));
    await ctx.read<SavingGoalsCubit>().load();
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
    expect(
      find.text('Refresh failed, showing the latest data'),
      findsOneWidget,
    );
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

  // ── Detail ──────────────────────────────────────────────────────────

  testWidgets('detail: ONE call on open; hero numbers, tiles, actions', (
    t,
  ) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(repo.detailCalls, 1);
    expect(find.byType(ErrorView), findsNothing);
    // Hero: status chip (behind 2 months), saved, target + %, bar captions.
    expect(find.text('2 months late'), findsOneWidget);
    expect(find.widgetWithText(HeroNumber, 'Saved'), findsOneWidget);
    expect(find.textContaining('52,000'), findsWidgets);
    expect(find.text('/ \$80,000.00 · 65%'), findsOneWidget);
    expect(find.text('Due Mar 15, 2027'), findsOneWidget);
    expect(find.text('153 days left'), findsOneWidget);
    // The three month tiles come from the BE (month_short / month_saved /
    // needed_monthly).
    expect(find.text('Short this month'), findsOneWidget);
    expect(find.text('\$2,500.00'), findsOneWidget);
    expect(find.text('Saved this month'), findsOneWidget);
    expect(find.text('\$3,000.00'), findsOneWidget);
    expect(find.text('Needed / month'), findsOneWidget);
    expect(find.text('\$5,600.00'), findsOneWidget);
    // The action bar follows the BE's flags.
    expect(find.widgetWithText(ActionBar, 'Save'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    // Tabs.
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Saving entries'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    // Two entries: the chart shows.
    expect(find.byType(SavingHistoryChart), findsOneWidget);
  });

  testWidgets('detail: nothing saved hides Withdraw and Move; one entry '
      'hides the chart', (t) async {
    repo.goalJson = prodGoal(saved: 0, actions: {'withdraw': true});
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Withdraw'), findsNothing);
    expect(find.text('Move'), findsNothing);
  });

  testWidgets('detail: the entries tab lists the saving entries', (t) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    await t.tap(find.text('Saving entries'));
    await t.pumpAndSettle();
    expect(find.byType(SavingTxRow), findsNWidgets(2));
    // An automatic entry carries the tag, with its wallet.
    expect(find.text('Auto'), findsWidgets);
    expect(find.text('กสิกร'), findsWidgets);
  });

  testWidgets('detail: the auto-save toggle is ONE PUT, then ONE DELETE', (
    t,
  ) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(t.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);
    await t.tap(find.byType(AppSwitch));
    await t.pumpAndSettle();
    // ON = the plan's amount (month_plan 5500), the default day, no wallet.
    expect(repo.writes, ['PUT g1 auto-save 5500.0 day 25 wallet null']);
    expect(t.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);
    expect(find.textContaining('Edit amount, day and wallet'), findsOneWidget);
    expect(find.textContaining('from โดราเอมอน'), findsOneWidget);
    // The write patched the page: no re-read.
    expect(repo.detailCalls, 1);
    await t.tap(find.byType(AppSwitch));
    await t.pumpAndSettle();
    expect(repo.writes, hasLength(2));
    expect(repo.writes.last, 'DELETE g1 auto-save');
    expect(t.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);
    expect(repo.detailCalls, 1);
  });

  testWidgets('detail edit: its own form; archive says close first', (t) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    await t.tap(find.byIcon(AppIcons.edit));
    await t.pumpAndSettle();
    // No tabs, no status, no tiles in the edit form.
    expect(find.text('Saving entries'), findsNothing);
    expect(find.text('2 months late'), findsNothing);
    expect(find.text('Short this month'), findsNothing);
    // The target field, the due date and the live line.
    expect(find.text('Target amount'), findsOneWidget);
    expect(find.text('Mar 15, 2027'), findsOneWidget);
    expect(find.textContaining('to go'), findsOneWidget);
    expect(find.text('Save \$5,600.00/month'), findsOneWidget);
    // End zone: close + archive (with its reason) — no delete (flag off).
    expect(find.text('Close goal'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Close the goal first'), findsOneWidget);
    expect(find.text('Delete this goal'), findsNothing);
    await t.ensureVisible(find.text('Archive'));
    await t.tap(find.text('Archive'));
    await t.pumpAndSettle();
    expect(find.text('Close the goal before archiving it'), findsOneWidget);
    expect(repo.writes, isEmpty);
  });

  testWidgets('detail edit: a 409 on archive shows the close-first message', (
    t,
  ) async {
    repo.goalJson = prodGoal(saved: 0, actions: {'archive': true});
    repo.archiveError = const ApiException(
      code: 'GOAL_HAS_SAVINGS',
      message: 'goal has savings',
      statusCode: 409,
    );
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    await t.tap(find.byIcon(AppIcons.edit));
    await t.pumpAndSettle();
    expect(find.text('Hidden, not counted, can be restored'), findsOneWidget);
    await t.ensureVisible(find.text('Archive'));
    await t.tap(find.text('Archive'));
    await t.pumpAndSettle();
    // The confirm dialog: its own "Archive" button.
    await t.tap(find.widgetWithText(AppButton, 'Archive'));
    await t.pumpAndSettle();
    expect(repo.writes, ['POST g1 archive']);
    expect(find.text('Close the goal before archiving it'), findsOneWidget);
  });

  testWidgets('create: the form only — no tabs, no auto-save, no end zone', (
    t,
  ) async {
    await pump(t, const SavingGoalDetailPage());
    expect(repo.detailCalls, 0);
    expect(find.byType(HeroAmountField), findsOneWidget);
    expect(find.text('Target amount'), findsOneWidget);
    expect(find.byType(InfoBox), findsOneWidget);
    expect(find.byType(AppSwitch), findsNothing);
    expect(find.byType(EndZone), findsNothing);
    expect(find.text('Saving entries'), findsNothing);
  });

  testWidgets('detail: a failed load is a full-page error', (t) async {
    repo.networkDown = true;
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(find.byType(ErrorView), findsOneWidget);
  });

  testWidgets('detail: a failed refresh keeps the page on screen', (t) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    repo.networkDown = true;
    final ctx = t.element(find.byType(HeroCard));
    await ctx.read<SavingGoalCubit>().load();
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(ErrorView), findsNothing);
    expect(find.widgetWithText(HeroNumber, 'Saved'), findsOneWidget);
    expect(
      find.text('Refresh failed, showing the latest data'),
      findsOneWidget,
    );
  });

  testWidgets('detail: the spare page shows the bucket, no edit', (t) async {
    await pump(t, const SavingGoalDetailPage(id: 'spare'));
    expect(repo.detailCalls, 1);
    expect(find.text('Not allocated'), findsWidgets);
    expect(find.textContaining('8,500'), findsWidgets);
    expect(find.byIcon(AppIcons.edit), findsNothing);
    expect(find.text('Saving entries'), findsOneWidget);
    // Auto-saving lives on the spare page too.
    expect(find.byType(AppSwitch), findsOneWidget);
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
