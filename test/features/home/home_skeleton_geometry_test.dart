import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:chubi_pocket/features/home/domain/dashboard.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/pages/home_page.dart';
import 'package:chubi_pocket/features/notifications/data/notifications_repository.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/theme_builder.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Dash extends MockCubit<DashboardState> implements DashboardCubit {}

class _Tx extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Acc extends MockCubit<AccountsState> implements AccountsCubit {}

class _Bud extends MockCubit<BudgetsState> implements BudgetsCubit {}

class _Goals extends MockCubit<SavingGoalsState> implements SavingGoalsCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _NotifRepo extends Fake implements NotificationsRepository {}

Map<String, dynamic> _cat(String id, String name) => {
  'id': id,
  'name': name,
  'type': 'expense',
  'icon_code': null,
  'is_system': false,
};

/// A typical Home as the BE sends it (the owner's restored prod data,
/// 2026-10-13: a few transactions, one budget, nothing scheduled, nothing to
/// answer — the "right now" to-do block is empty for most users).
Map<String, dynamic> _prodDashboard() => {
  'month': '2026-10',
  'from': '2026-10-01',
  'to': '2026-10-31',
  'today': '2026-10-13',
  'currency': 'THB',
  'net_worth': {
    'total': 18250.5,
    'assets': 21000,
    'liabilities': -2749.5,
    'accounts_count': 3,
  },
  'summary': {
    'income': 25000,
    'expense': 6420,
    'net': 18580,
    'transaction_count': 8,
  },
  'previous': {
    'income': 25000,
    'expense': 7310,
    'net': 17690,
    'transaction_count': 11,
  },
  'top_categories': [
    {'category': _cat('c1', 'Food'), 'expense': 3200, 'count': 4},
    {'category': _cat('c2', 'Transport'), 'expense': 1800, 'count': 2},
    {'category': null, 'expense': 1420, 'count': 2},
  ],
  'other_expense': 0,
  'trend': [
    {'month': '2026-08', 'income': 25000, 'expense': 8100},
    {'month': '2026-09', 'income': 25000, 'expense': 7310},
    {'month': '2026-10', 'income': 25000, 'expense': 6420},
  ],
  'upcoming': {
    'days': 7,
    'items': <Object>[],
    'total_expense': 0,
    'total_income': 0,
  },
  'budgets': {
    'count': 1,
    'total_budget': 5000,
    'total_spent': 3200,
    'utilization_pct': 64,
    'over_limit_count': 0,
  },
  'debts': {'owed_to_me': 500, 'i_owe': 0, 'net': 500, 'open_count': 1},
  'saving_goals': {
    'count': 0,
    'completed_count': 0,
    'total_target': 0,
    'total_current': 0,
    'progress_pct': 0,
  },
  'recent': <Object>[],
  'pending': {'total': 0, 'items': <Object>[]},
  'attention': {'total': 0, 'items': <Object>[]},
  'badges': {'unread_notifications': 0, 'pending_drafts': 0},
};

/// Home's first-load skeleton has the heights of its real cards (owner
/// 2026-10-13: skeletons mirror the real layout, nothing jumps when the data
/// lands). Measured on the real page with prod-shaped data.
void main() {
  testWidgets('home skeleton slots = the real card heights', (t) async {
    // The test font draws every glyph as a full square, far wider than the
    // app's fonts: a long row "overflows" here only. Heights are what this
    // test is about, so layout overflow reports are muted.
    final onError = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('RenderFlex overflowed')) {
        onError?.call(d);
      }
    };
    addTearDown(() => FlutterError.onError = onError);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(412, 3000);
    addTearDown(t.view.reset);

    final dash = _Dash();
    when(() => dash.state).thenReturn(
      DashboardState(
        status: DashboardStatus.loaded,
        data: Dashboard.fromJson(_prodDashboard()),
      ),
    );
    when(() => dash.loadIfNeeded()).thenAnswer((_) async {});
    final tx = _Tx();
    when(() => tx.state).thenReturn(const TransactionsState());
    final acc = _Acc();
    when(() => acc.state).thenReturn(const AccountsState());
    final bud = _Bud();
    when(() => bud.state).thenReturn(const BudgetsState());
    final goals = _Goals();
    when(() => goals.state).thenReturn(const SavingGoalsState());
    final unread = _Unread();
    when(() => unread.state).thenReturn(0);
    final pending = _Pending();
    when(() => pending.state).thenReturn(const PendingState());
    final auth = _Auth();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());

    await t.pumpWidget(
      RepositoryProvider<NotificationsRepository>.value(
        value: _NotifRepo(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DashboardCubit>.value(value: dash),
            BlocProvider<TransactionsCubit>.value(value: tx),
            BlocProvider<AccountsCubit>.value(value: acc),
            BlocProvider<BudgetsCubit>.value(value: bud),
            BlocProvider<SavingGoalsCubit>.value(value: goals),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<AuthCubit>.value(value: auth),
          ],
          child: MaterialApp(
            theme: ThemeBuilder.build(
              theme: ThemeRegistry.byId(ThemeRegistry.defaultThemeId),
              font: FontRegistry.inter,
              brightness: Brightness.light,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('th'),
            builder: (context, child) => AppUiConfig(child: child!),
            home: const HomePage(),
          ),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));

    double h(String type, [int i = 0]) => t
        .getSize(
          find.byWidgetPredicate((w) => w.runtimeType.toString() == type).at(i),
        )
        .height;

    final real = (
      snapshot: h('_NetWorthCard'),
      todo: h('_TodoSection'),
      period: h('_MonthBar'),
      kpi: h('_MonthSlide'),
      chart1: h('_MonthSlide', 1),
      chart2: h('_MonthSlide', 2),
      tiles: h('_Tiles'),
    );

    const shape = HomePage.skeletonShape;
    const tolerance = 4.0;
    expect(real.todo, 0, reason: 'typical home: nothing waiting');
    expect(
      shape.snapshots.single,
      closeTo(real.snapshot, tolerance),
      reason: 'measured: $real',
    );
    expect(
      DashboardPageSkeleton.periodHeight,
      closeTo(real.period, tolerance),
      reason: 'measured: $real',
    );
    expect(
      shape.kpis.single,
      closeTo(real.kpi, tolerance),
      reason: 'measured: $real',
    );
    expect(
      shape.charts[0],
      closeTo(real.chart1, tolerance),
      reason: 'measured: $real',
    );
    expect(
      shape.charts[1],
      closeTo(real.chart2, tolerance),
      reason: 'measured: $real',
    );
    expect(
      shape.tilesHeight,
      closeTo(real.tiles, tolerance),
      reason: 'measured: $real',
    );
  });
}
