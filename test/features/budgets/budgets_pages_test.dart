import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/budgets/data/budgets_repository.dart';
import 'package:chubi_pocket/features/budgets/domain/budget.dart';
import 'package:chubi_pocket/features/budgets/domain/budget_detail.dart';
import 'package:chubi_pocket/features/budgets/domain/budget_period.dart';
import 'package:chubi_pocket/features/budgets/presentation/budget_draft.dart';
import 'package:chubi_pocket/features/budgets/presentation/budget_labels.dart';
import 'package:chubi_pocket/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:chubi_pocket/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:chubi_pocket/features/budgets/presentation/pages/budgets_list_page.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Dashboard extends MockCubit<DashboardState> implements DashboardCubit {}

class _Transactions extends MockCubit<TransactionsState>
    implements TransactionsCubit {}

const _down = ApiException(code: 'NETWORK_ERROR', message: 'no connection');

/// Runs the REAL model parsing on prod-shaped bodies, or fails like the
/// network does.
class _Repo extends Fake implements BudgetsRepository {
  Map<String, dynamic> detail = _recurringDetail();
  Map<String, dynamic> listBody = _list();
  bool networkDown = false;
  final calls = <String>[];

  void _hit(String call) {
    calls.add(call);
    if (networkDown) throw _down;
  }

  @override
  Future<BudgetList> list({
    BudgetFilter filter = BudgetFilter.active,
    BudgetSort sort = BudgetSort.risk,
    BudgetHealth health = BudgetHealth.all,
  }) async {
    final h = health == BudgetHealth.all ? '' : ':${health.name}';
    _hit('list:${filter.name}:${sort.name}$h');
    return BudgetList.fromJson(listBody);
  }

  @override
  Future<BudgetDetail> get(
    String id, {
    String? periodId,
    bool deletePreview = false,
  }) async {
    _hit(
      'get:$id${periodId == null ? '' : ':$periodId'}'
      '${deletePreview ? ':preview' : ''}',
    );
    return BudgetDetail.fromJson({
      ...detail,
      if (deletePreview)
        'delete_preview': {
          'periods': 6,
          'overridden_periods': 2,
          'categories': 3,
          'wallets': 1,
        },
    });
  }

  /// What the next period write answers (the page at that period).
  Map<String, dynamic>? periodAnswer;

  @override
  Future<BudgetDetail> updatePeriod(
    String id,
    String periodId, {
    required double? amount,
    required String? note,
  }) async {
    _hit('period:$id:$periodId:${amount ?? 'base'}');
    return BudgetDetail.fromJson(periodAnswer ?? detail);
  }

  @override
  Future<BudgetDetail> archive(String id) async {
    _hit('archive:$id');
    final d = detail;
    return BudgetDetail.fromJson({
      ...d,
      'budget': {...(d['budget'] as Map<String, dynamic>), 'state': 'archived'},
    });
  }

  @override
  Future<void> delete(String id) async => _hit('delete:$id');
}

Map<String, dynamic> _account() => {
  'id': 'a1',
  'name': 'KBank',
  'icon_code': null,
  'logo_url': null,
  'type': 'bank',
  'group': 'asset',
  'currency': 'THB',
  'archived': false,
};

Map<String, dynamic> _category() => {
  'id': 'c1',
  'name': 'Food',
  'type': 'expense',
  'icon_code': null,
  'is_system': false,
  'system_kind': null,
  'parent_id': null,
};

Map<String, dynamic> _period({
  String id = 'p1',
  int seq = 5,
  String start = '2026-10-01',
  String? end = '2026-10-31',
  bool current = true,
  double used = 3120,
  double expected = 900,
  double amount = 8000,
  String status = 'pace',
  String tone = 'neutral',
  bool overridden = false,
}) => {
  'id': id,
  'seq': seq,
  'start': start,
  'end': end,
  'amount': amount,
  'base_amount': 8000,
  'overridden': overridden,
  'note': null,
  'is_current': current,
  'used': used,
  'expected': expected,
  'remaining': amount - used,
  'over_by': used > amount ? used - amount : 0,
  'pct': (used / amount * 100).round(),
  'status': status,
  'tone': tone,
  'days_left': current ? 24 : null,
  'on_pace_to_exceed': status == 'pace',
};

/// A budget as `listBudgets` / `getBudget` send it.
Map<String, dynamic> _budget({
  String id = 'b1',
  String name = 'อาหาร',
  bool recurring = true,
  Map<String, dynamic>? period,
  Map<String, dynamic> end = const {
    'kind': 'none',
    'date': null,
    'count': null,
  },
  String state = 'active',
  Map<String, dynamic>? actions,
}) => {
  'id': id,
  'name': name,
  'description': 'กินนอกบ้าน',
  'note': null,
  'icon_code': null,
  'amount': 8000,
  'warn_pct': 80,
  'scope': {
    'all': false,
    'categories': [
      {'category': _category(), 'include_children': true},
    ],
    'tags': ['เที่ยว'],
    'wallets': [_account()],
  },
  'recurring': recurring,
  'rule': recurring ? {'freq': 'monthly', 'interval': 1} : null,
  'start_date': '2026-05-01',
  'end': end,
  'state': state,
  'closed_on': null,
  'period': period ?? _period(),
  'actions':
      actions ??
      {'edit': true, 'close': !recurring, 'archive': true, 'restore': false},
  'created_at': '2026-05-01T08:00:00Z',
  'updated_at': '2026-10-01T08:00:00Z',
};

Map<String, dynamic> _list() => {
  'summary': {
    'active_count': 2,
    'over_count': 1,
    'warn_count': 0,
    'pace_count': 1,
    'ended_count': 3,
    'archived_count': 0,
    'total_limit': 12000,
    'total_used': 7980,
    'total_remaining': 4020,
    'used_pct': 67,
    'counts': {'all': 2, 'ok': 1, 'near': 0, 'over': 1},
  },
  'data': [
    _budget(
      id: 'b2',
      name: 'ช้อปปิ้ง',
      period: _period(
        id: 'p9',
        used: 4860,
        amount: 4000,
        expected: 0,
        status: 'over',
        tone: 'danger',
      ),
    ),
    _budget(),
  ],
};

Map<String, dynamic> _item({
  String source = 'normal',
  String countsAs = 'used',
  String kind = 'transaction',
  String reason = 'category',
  String description = 'ข้าวมันไก่',
  String date = '2026-10-08',
  Map<String, dynamic>? category,
  List<String> tags = const [],
}) => {
  'kind': kind,
  'id': 'i-$description',
  'source': source,
  'counts_as': countsAs,
  'date': date,
  'amount': 60,
  'description': description,
  'category': category ?? _category(),
  'account': _account(),
  'tags': tags,
  'event': null,
  'recurring': null,
  'reason': reason,
};

Map<String, dynamic> _recurringDetail() => {
  'budget': _budget(),
  'forecast': {
    'elapsed_days': 8,
    'total_days': 31,
    'daily_allowance': 165,
    'avg_daily': 390,
    'avg_monthly': null,
    'forecast_end': 12990,
    'forecast_over_by': 4990,
    'forecast_over_date': '2026-10-19',
    'remaining_after_expected': 3980,
    'this_month': null,
    'history_avg': 7530,
    'history_count': 6,
    'available': 4880,
    'projected_end': 12990,
    'days_left': 24,
    'pace_pct': 26,
  },
  'by_source': [
    {'source': 'normal', 'counts_as': 'used', 'count': 18, 'amount': 2460},
    {'source': 'event', 'counts_as': 'used', 'count': 2, 'amount': 660},
    {'source': 'upcoming', 'counts_as': 'expected', 'count': 1, 'amount': 450},
    {'source': 'pending', 'counts_as': 'expected', 'count': 2, 'amount': 270},
  ],
  'by_category': [
    {'category': _category(), 'amount': 3120, 'pct': 100},
  ],
  'periods': {
    'data': [
      _period(),
      _period(
        id: 'p0',
        seq: 4,
        start: '2026-09-01',
        end: '2026-09-30',
        current: false,
        used: 8460,
        expected: 0,
        status: 'over',
        tone: 'danger',
      ),
    ],
    'has_more': true,
  },
  'items': {
    'data': [
      _item(
        source: 'upcoming',
        countsAs: 'expected',
        kind: 'recurring_item',
        description: 'ค่าเน็ต',
        date: '2026-10-20',
        reason: 'wallet',
      ),
      _item(),
      _item(
        description: 'ก๋วยเตี๋ยว',
        reason: 'sub_category',
        category: {
          ..._category(),
          'id': 'c2',
          'name': 'Noodles',
          'parent_id': 'c1',
        },
      ),
      _item(
        description: 'ตั๋วรถ',
        reason: 'tag',
        date: '2026-10-07',
        tags: ['เที่ยว'],
      ),
    ],
    'pagination': {'page': 1, 'per_page': 20, 'total': 4, 'total_pages': 1},
  },
};

Map<String, dynamic> _openEndedDetail() => {
  ..._recurringDetail(),
  'budget': _budget(
    id: 'b3',
    name: 'รีโนเวท',
    recurring: false,
    period: _period(
      id: 'p7',
      start: '2026-08-01',
      end: null,
      used: 64300,
      amount: 100000,
      expected: 8500,
      status: 'ok',
    ),
  ),
  'periods': {'data': <dynamic>[], 'has_more': false},
};

void main() {
  late _Repo repo;
  late QuickCreateContext registry;
  BudgetsCubit? budgets;
  late StreamController<TransactionsState> txBook;

  setUp(() {
    ToolbarToggleState.resetAll();
    repo = _Repo();
    registry = QuickCreateContext();
    txBook = StreamController<TransactionsState>.broadcast();
  });

  tearDown(() async {
    registry.dispose();
    await budgets?.close();
    await txBook.close();
  });

  Future<void> pump(WidgetTester t, Widget page) async {
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final accounts = _Accounts();
    final categories = _Categories();
    final tags = _Tags();
    final dashboard = _Dashboard();
    final transactions = _Transactions();
    final cubit = budgets = BudgetsCubit(repository: repo);
    t.view.physicalSize = const Size(800, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => tags.state).thenReturn(const TagsState());
    when(() => tags.loadIfNeeded()).thenAnswer((_) async {});
    when(() => dashboard.state).thenReturn(const DashboardState());
    whenListen(
      transactions,
      txBook.stream,
      initialState: const TransactionsState(),
    );
    await t.pumpWidget(
      RepositoryProvider<BudgetsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<DashboardCubit>.value(value: dashboard),
            BlocProvider<TransactionsCubit>.value(value: transactions),
            BlocProvider<BudgetsCubit>.value(value: cubit),
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
            home: page,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  group('model', () {
    test('a budget list parses the BE statuses and the summary', () {
      final l = BudgetList.fromJson(_list());
      expect(l.summary.activeCount, 2);
      expect(l.summary.overCount, 1);
      expect(l.budgets.first.period.status, BudgetStatus.over);
      expect(l.budgets.first.period.tone, BudgetTone.danger);
      expect(l.budgets.first.period.overBy, 860);
      expect(l.budgets.last.recurring, isTrue);
      expect(l.budgets.last.rule?.freq, 'monthly');
      expect(l.budgets.last.scope.tags, ['เที่ยว']);
      expect(l.budgets.last.scope.categories.single.includeChildren, isTrue);
      expect(l.summary.totalLimit, 12000);
      expect(l.summary.totalUsed, 7980);
      expect(l.summary.totalRemaining, 4020);
      expect(l.summary.usedPct, 67);
      expect(l.summary.countAll, 2);
      expect(l.summary.countOk, 1);
      expect(l.summary.countOver, 1);
      expect(l.budgets.last.period.onPaceToExceed, isTrue);
    });

    test('the pace tick: elapsed fraction of the period, null when open', () {
      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 31);
      expect(budgetPaceFraction(start, end, DateTime(2026, 10, 16)), 0.5);
      expect(budgetPaceFraction(start, end, DateTime(2026, 9, 1)), 0);
      expect(budgetPaceFraction(start, end, DateTime(2026, 12, 1)), 1);
      expect(budgetPaceFraction(start, null, DateTime(2026, 10, 16)), isNull);
      expect(budgetPaceFraction(start, start, DateTime(2026, 10, 1)), isNull);
    });

    test('the detail parses forecast, sources, periods and items', () {
      final d = BudgetDetail.fromJson(_recurringDetail());
      expect(d.forecast.dailyAllowance, 165);
      expect(d.forecast.forecastOverDate, DateTime(2026, 10, 19));
      expect(d.bySource.map((s) => s.source), [
        BudgetSource.normal,
        BudgetSource.event,
        BudgetSource.upcoming,
        BudgetSource.pending,
      ]);
      expect(d.bySource.where((s) => s.expected).length, 2);
      expect(d.periods.hasMore, isTrue);
      expect(d.items.items.first.expected, isTrue);
      // The 0.4.0 forecast numbers and each row's reason.
      expect(d.forecast.available, 4880);
      expect(d.forecast.projectedEnd, 12990);
      expect(d.forecast.daysLeft, 24);
      expect(d.forecast.pacePct, 26);
      expect(d.items.items.map((i) => i.reason), [
        BudgetReason.wallet,
        BudgetReason.category,
        BudgetReason.subCategory,
        BudgetReason.tag,
      ]);
    });

    test('a period write answers at that period: only an old one patches', () {
      final d = BudgetDetail.fromJson(_recurringDetail());
      Map<String, dynamic> at(String id, double amount) => {
        ..._recurringDetail(),
        'budget': _budget(
          period: _period(
            id: id,
            amount: amount,
            overridden: true,
            current: id == 'p1',
          ),
        ),
      };
      final old = d.afterPeriodWrite(BudgetDetail.fromJson(at('p0', 9000)));
      expect(old.budget.period.id, 'p1');
      expect(old.periods.periods.last.amount, 9000);
      expect(old.periods.periods.first.amount, 8000);
      final cur = d.afterPeriodWrite(BudgetDetail.fromJson(at('p1', 7000)));
      expect(cur.budget.period.amount, 7000);
    });

    test('an open-ended budget has no period end', () {
      final d = BudgetDetail.fromJson(_openEndedDetail());
      expect(d.budget.openEnded, isTrue);
      expect(d.budget.period.end, isNull);
      expect(d.budget.actions.close, isTrue);
    });

    test('the setup draft round-trips to the write body', () {
      final b = Budget.fromJson(_budget());
      final json = BudgetDraft.from(b).toWrite().toJson(apply: 'all');
      expect(json['name'], 'อาหาร');
      expect(json['amount'], 8000);
      expect(json['warn_pct'], 80);
      expect(json['recurring'], isTrue);
      expect(json['rule'], {'freq': 'monthly', 'interval': 1});
      expect(json['start_date'], '2026-05-01');
      expect(json['end'], {'kind': 'none'});
      expect(json['apply'], 'all');
      final scope = json['scope'] as Map<String, dynamic>;
      expect(scope['all'], isFalse);
      expect(scope['tags'], ['เที่ยว']);
      expect(scope['wallet_ids'], ['a1']);
      expect(scope['categories'], [
        {'id': 'c1', 'include_children': true},
      ]);
      // no currency anywhere
      expect(json.containsKey('currency'), isFalse);
    });

    test(
      'a one-off keeps no rule and an "everything" scope sends no lists',
      () {
        final d = BudgetDraft.blank().copyWith(
          name: 'ทริป',
          amount: '5,000',
          recurring: false,
          allScope: true,
          end: BudgetEnd.onDate(DateTime(2026, 10, 10)),
        );
        final json = d.toWrite().toJson();
        expect(json.containsKey('rule'), isFalse);
        expect(json['end'], {'kind': 'date', 'date': '2026-10-10'});
        final scope = json['scope'] as Map<String, dynamic>;
        expect(scope['all'], isTrue);
        expect(scope['categories'], isEmpty);
        expect(d.scopeEmpty, isFalse);
        expect(BudgetDraft.blank().scopeEmpty, isTrue);
      },
    );

    test('a period change asks "which periods", a text change does not', () {
      final b = BudgetDraft.from(Budget.fromJson(_budget()));
      expect(b.periodShapeDiffers(b.copyWith(note: 'x', name: 'y')), isFalse);
      expect(b.periodShapeDiffers(b.copyWith(amount: '9,000')), isTrue);
      expect(b.periodShapeDiffers(b.copyWith(interval: 2)), isTrue);
    });
  });

  group('list page', () {
    testWidgets('opens with ONE call and lists the budgets', (t) async {
      await pump(t, const BudgetsListPage());
      expect(repo.calls, ['list:active:risk']);
      expect(find.text('ช้อปปิ้ง'), findsOneWidget);
      expect(find.text('อาหาร'), findsOneWidget);
      expect(find.text('Over'), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('a transaction write refreshes the spent figures', (t) async {
      await pump(t, const BudgetsListPage());
      expect(repo.calls, ['list:active:risk']);
      // A write bumps the revision.
      txBook.add(const TransactionsState(revision: 1));
      await t.pump(const Duration(milliseconds: 500));
      await t.pump();
      expect(repo.calls, ['list:active:risk', 'list:active:risk']);
      // A book-wide refresh (pending submit, debt settle) swaps the rows.
      txBook.add(TransactionsState(revision: 1, transactions: <Transaction>[]));
      await t.pump(const Duration(milliseconds: 500));
      await t.pump();
      expect(repo.calls.length, 3);
    });

    Future<void> openToolbar(WidgetTester t) async {
      await t.tap(find.byType(ToolbarToggleButton));
      await t.pumpAndSettle();
    }

    testWidgets('summary card: totals, tiles, 🔍; toolbar hidden by default', (
      t,
    ) async {
      await pump(t, const BudgetsListPage());
      final label = find.text('Current period · total used');
      final card = find.ancestor(of: label, matching: find.byType(AppCard));
      expect(card, findsOneWidget);
      final screen = t.view.physicalSize.width / t.view.devicePixelRatio;
      final r = t.getRect(label);
      expect(r.left, AppSpacing.lg * 2);
      expect(screen - r.right, greaterThanOrEqualTo(AppSpacing.lg * 2));
      expect(find.textContaining('฿7,980', findRichText: true), findsWidgets);
      expect(find.textContaining('of ฿12,000'), findsOneWidget);
      expect(find.text('฿4,020 left in total'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      for (final k in ['All', 'Normal', 'Near the limit', 'Over budget']) {
        expect(find.byKey(ValueKey('summaryTile:$k')), findsOneWidget);
      }
      // 🔍 in the card; the toolbar is hidden until it is tapped.
      expect(find.byIcon(AppIcons.search), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await openToolbar(t);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        t.getTopLeft(card).dy,
        lessThan(t.getTopLeft(find.byType(ListToolbar)).dy),
      );
    });

    testWidgets('search by name (local, no call)', (t) async {
      await pump(t, const BudgetsListPage());
      await openToolbar(t);
      await t.enterText(find.byType(TextField), 'ช้อป');
      await t.pump();
      expect(find.text('ช้อปปิ้ง'), findsOneWidget);
      expect(find.text('อาหาร'), findsNothing);
      await t.enterText(find.byType(TextField), 'zzz');
      await t.pump();
      expect(find.text('No matching budgets'), findsOneWidget);
      expect(repo.calls, ['list:active:risk']);
    });

    testWidgets('red dot on the 🔍 while hidden with a search typed', (
      t,
    ) async {
      await pump(t, const BudgetsListPage());
      await openToolbar(t);
      await t.enterText(find.byType(TextField), 'ช้อป');
      await t.pump();
      bool dot() =>
          t.widget<CardActionButton>(find.byType(CardActionButton)).showDot;
      expect(dot(), isFalse);
      await openToolbar(t); // hide again
      expect(find.byType(TextField), findsNothing);
      expect(dot(), isTrue);
    });

    testWidgets('status is ONE dropdown chip and changes the filter', (
      t,
    ) async {
      await pump(t, const BudgetsListPage());
      await openToolbar(t);
      expect(find.text('Status: Active'), findsOneWidget);
      await t.tap(find.text('Status: Active'));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Ended').last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls, ['list:active:risk', 'list:ended:risk']);
      expect(find.text('Status: Ended'), findsOneWidget);
    });

    testWidgets('a health tile is ONE call; the same tile clears it', (
      t,
    ) async {
      await pump(t, const BudgetsListPage());
      await t.tap(find.byKey(const ValueKey('summaryTile:Over budget')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls, ['list:active:risk', 'list:active:risk:over']);
      await t.tap(find.byKey(const ValueKey('summaryTile:Over budget')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls.last, 'list:active:risk');
    });

    testWidgets('a row: remaining on the name line, short caption, badges', (
      t,
    ) async {
      await pump(t, const BudgetsListPage());
      expect(find.textContaining('฿4,880', findRichText: true), findsOneWidget);
      expect(find.textContaining('฿860', findRichText: true), findsOneWidget);
      expect(find.text('Monthly · 24 days left'), findsNWidgets(2));
      expect(find.text('Used ฿3,120 of ฿8,000'), findsOneWidget);
      expect(find.text('On pace to exceed'), findsOneWidget);
      expect(find.text('Over'), findsOneWidget);
    });

    testWidgets('network down → full-page error + retry', (t) async {
      repo.networkDown = true;
      await pump(t, const BudgetsListPage());
      expect(find.byType(ErrorView), findsOneWidget);
      repo.networkDown = false;
      await t.tap(find.text('Retry'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('อาหาร'), findsOneWidget);
    });

    testWidgets('no budgets → the empty state with the add tile', (t) async {
      repo.listBody = {'summary': _list()['summary'], 'data': <dynamic>[]};
      await pump(t, const BudgetsListPage());
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.byType(AddTile), findsOneWidget);
    });
  });

  group('budget page', () {
    Future<void> settle(WidgetTester t) async {
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    }

    /// The recurring detail with the previous period overridden to 9,000.
    Map<String, dynamic> overriddenDetail() {
      final d = _recurringDetail();
      final periods = (d['periods'] as Map<String, dynamic>)['data'] as List;
      return {
        ...d,
        'periods': {
          'data': [
            periods.first,
            _period(
              id: 'p0',
              seq: 4,
              start: '2026-09-01',
              end: '2026-09-30',
              current: false,
              used: 8460,
              expected: 0,
              amount: 9000,
              status: 'over',
              tone: 'danger',
              overridden: true,
            ),
          ],
          'has_more': true,
        },
      };
    }

    testWidgets('hero: remaining, target, bar caption with the pace, tiles', (
      t,
    ) async {
      await pump(t, const BudgetDetailPage(id: 'b1'));
      expect(repo.calls, ['get:b1']);
      expect(find.byType(HeroCard), findsOneWidget);
      expect(find.text('Still available'), findsOneWidget);
      expect(find.textContaining('฿4,880', findRichText: true), findsWidgets);
      expect(find.text('/ ฿8,000'), findsOneWidget);
      expect(find.text('Used ฿3,120'), findsOneWidget);
      expect(find.text('Should be at 26% by today'), findsOneWidget);
      // The chips: the period kind and the range with the day counter.
      expect(find.text('🔁 Monthly'), findsOneWidget);
      expect(find.textContaining('day 8/31'), findsOneWidget);
      // The 3 tiles are the BE's forecast numbers.
      expect(
        find.byKey(const ValueKey('summaryTile:Can spend per day')),
        findsOneWidget,
      );
      expect(find.textContaining('฿165'), findsOneWidget);
      expect(find.text('Forecast at the end'), findsOneWidget);
      expect(find.textContaining('฿12,990'), findsOneWidget);
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('24 days'), findsOneWidget);
      // No action bar, no "Setup" tab, no old dashboard sections.
      expect(find.byType(ActionBar), findsNothing);
      expect(find.text('Setup'), findsNothing);
      expect(find.text('By source'), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('an over-budget period reads "Over budget" with the excess', (
      t,
    ) async {
      repo.detail = {
        ..._recurringDetail(),
        'budget': _budget(
          period: _period(
            used: 8860,
            expected: 0,
            status: 'over',
            tone: 'danger',
          ),
        ),
      };
      await pump(t, const BudgetDetailPage(id: 'b1'));
      expect(find.text('Over budget'), findsWidgets);
      expect(find.textContaining('฿860', findRichText: true), findsWidgets);
      expect(find.text('Still available'), findsNothing);
    });

    testWidgets('settings, then the note, above the tabs', (t) async {
      await pump(t, const BudgetDetailPage(id: 'b1'));
      expect(find.byType(SettingsSection), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(
        find.text('What this budget counts, and when it warns'),
        findsOneWidget,
      );
      expect(find.text('What it counts'), findsOneWidget);
      expect(find.textContaining('Food + sub'), findsOneWidget);
      expect(find.text('Warn at'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('Repeat every period'), findsOneWidget);
      expect(find.byType(NoteSection), findsOneWidget);
      final settings = t.getTopLeft(find.byType(SettingsSection)).dy;
      final note = t.getTopLeft(find.byType(NoteSection)).dy;
      final tabs = t.getTopLeft(find.text('This period')).dy;
      expect(settings, lessThan(note));
      expect(note, lessThan(tabs));
    });

    testWidgets('items: day headers and WHY each row counts', (t) async {
      await pump(t, const BudgetDetailPage(id: 'b1'));
      expect(find.byType(TxRow), findsNWidgets(4));
      expect(find.byType(DateGroupHeader), findsNWidgets(3));
      expect(
        find.textContaining(
          'Counted because: wallet KBank',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Counted because: category Food',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Counted because: sub-category of Food',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Counted because: tag เที่ยว', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('all periods: a row per period, tap = edit its limit', (
      t,
    ) async {
      repo.periodAnswer = {
        ..._recurringDetail(),
        'budget': _budget(
          period: _period(
            id: 'p0',
            seq: 4,
            start: '2026-09-01',
            end: '2026-09-30',
            current: false,
            used: 8460,
            expected: 0,
            amount: 9000,
            status: 'over',
            tone: 'danger',
            overridden: true,
          ),
        ),
      };
      await pump(t, const BudgetDetailPage(id: 'b1'));
      await t.tap(find.text('All periods'));
      await settle(t);
      expect(find.byType(ProgressCard), findsNWidgets(2));
      expect(find.text('Used ฿8,460 of ฿8,000'), findsOneWidget);
      await t.tap(find.byType(ProgressCard).last);
      await settle(t);
      expect(find.text('Edit this period only'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, '9000');
      await t.pump();
      await t.tap(find.text('Save').last);
      await settle(t);
      // ONE call: the PUT; the answer patches the row, the hero stays on the
      // CURRENT period.
      expect(repo.calls, ['get:b1', 'period:b1:p0:9000.0']);
      expect(
        find.textContaining('Used ฿8,460 of ฿9,000', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('฿4,880', findRichText: true), findsWidgets);
    });

    testWidgets('an overridden period goes back to the base amount', (t) async {
      repo.detail = overriddenDetail();
      repo.periodAnswer = overriddenDetail();
      await pump(t, const BudgetDetailPage(id: 'b1'));
      await t.tap(find.text('All periods'));
      await settle(t);
      await t.tap(find.byType(ProgressCard).last);
      await settle(t);
      await t.tap(find.text('Back to the base amount (฿8,000)'));
      await t.pump();
      await t.tap(find.text('Save').last);
      await settle(t);
      expect(repo.calls.last, 'period:b1:p0:base');
    });

    testWidgets('a failed reload keeps the page and says why', (t) async {
      await pump(t, const BudgetDetailPage(id: 'b1'));
      repo.networkDown = true;
      txBook.add(const TransactionsState(revision: 1));
      await t.pump(const Duration(milliseconds: 500));
      await t.pump();
      expect(repo.calls, ['get:b1', 'get:b1']);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('no connection'), findsOneWidget);
      expect(find.text('Still available'), findsOneWidget);
      expect(find.byType(TxRow), findsNWidgets(4));
    });

    testWidgets('a one-off budget is one page: no tabs, items below', (
      t,
    ) async {
      repo.detail = _openEndedDetail();
      await pump(t, const BudgetDetailPage(id: 'b3'));
      expect(find.text('All periods'), findsNothing);
      expect(find.byType(SettingsSection), findsOneWidget);
      expect(find.text('This period'), findsOneWidget);
      expect(find.byType(TxRow), findsNWidgets(4));
    });

    Future<void> openEdit(WidgetTester t) async {
      await t.tap(find.byIcon(AppIcons.edit).first);
      await t.pumpAndSettle();
    }

    testWidgets('edit: its own form — limit field, dates, settings, end zone', (
      t,
    ) async {
      await pump(t, const BudgetDetailPage(id: 'b1'));
      await openEdit(t);
      expect(find.byType(ModeActionBar), findsOneWidget);
      final field = t.widget<HeroAmountField>(find.byType(HeroAmountField));
      expect(field.controller.text, '8,000');
      expect(find.text('Budget limit'), findsOneWidget);
      expect(find.byType(InfoBox), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Every expense'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Warn at'), findsOneWidget);
      expect(find.text('Repeat every period'), findsOneWidget);
      // Hidden, not greyed: bar, tiles, forecast, items, tabs.
      expect(find.byType(HeroBar), findsNothing);
      expect(find.text('Can spend per day'), findsNothing);
      expect(find.byType(TxRow), findsNothing);
      expect(find.text('All periods'), findsNothing);
      // End zone: archive + delete (no close: the BE says it can't).
      expect(find.byType(EndZone), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Delete this budget'), findsOneWidget);
      expect(find.text('Close the budget'), findsNothing);
    });

    testWidgets('edit: an open-ended budget can be closed', (t) async {
      repo.detail = _openEndedDetail();
      await pump(t, const BudgetDetailPage(id: 'b3'));
      await openEdit(t);
      expect(find.text('Close the budget'), findsOneWidget);
    });

    testWidgets('archive: confirm, ONE call, the page takes the answer', (
      t,
    ) async {
      await pump(t, const BudgetDetailPage(id: 'b1'));
      await openEdit(t);
      await t.tap(find.text('Archive'));
      await t.pumpAndSettle();
      expect(find.text('Archive this budget?'), findsOneWidget);
      await t.tap(find.text('Archive').last);
      await t.pumpAndSettle();
      expect(repo.calls, ['get:b1', 'archive:b1']);
      expect(find.byType(ModeActionBar), findsNothing);
    });

    testWidgets('delete asks first and calls nothing on cancel', (t) async {
      await pump(t, const BudgetDetailPage(id: 'b1'));
      await openEdit(t);
      await t.tap(find.text('Delete this budget'));
      await t.pumpAndSettle();
      expect(find.text('Delete this budget?'), findsOneWidget);
      // The BE's preview, printed as sent.
      expect(
        find.textContaining(
          'Deletes 6 periods (2 adjusted) · 3 categories · 1 wallets',
        ),
        findsOneWidget,
      );
      await t.tap(find.text('Cancel').last);
      await t.pumpAndSettle();
      // ONE preview call on the button; nothing else on cancel.
      expect(repo.calls, ['get:b1', 'get:b1:preview']);
    });

    testWidgets('create: no call, the form opens, no end zone', (t) async {
      await pump(t, const BudgetDetailPage());
      expect(repo.calls, isEmpty);
      expect(find.byType(ModeActionBar), findsOneWidget);
      expect(find.byType(HeroAmountField), findsOneWidget);
      expect(find.byType(EndZone), findsNothing);
      expect(find.byType(HeroBar), findsNothing);
    });

    testWidgets('network down → full-page error', (t) async {
      repo.networkDown = true;
      await pump(t, const BudgetDetailPage(id: 'b1'));
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('a malformed body → error, not an endless skeleton', (t) async {
      repo.detail = {
        'budget': {'name': 'x'},
      };
      await pump(t, const BudgetDetailPage(id: 'b1'));
      expect(find.byType(ErrorView), findsOneWidget);
    });
  });
}
