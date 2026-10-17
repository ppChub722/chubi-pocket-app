import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurrence_rule.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_summary.dart';
import 'package:chubi_pocket/features/recurring/presentation/pages/recurring_detail_page.dart';
import 'package:chubi_pocket/features/recurring/presentation/pages/recurring_home_page.dart';
import 'package:chubi_pocket/features/recurring/presentation/recurring_draft.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
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

const _down = ApiException(code: 'NETWORK_ERROR', message: 'no connection');

/// Runs the REAL model parsing on prod-shaped bodies, or fails like the
/// network does.
class _Repo extends Fake implements RecurringRepository {
  Map<String, dynamic> detail = _prodDetail();
  List<Map<String, dynamic>> listData = [_prodRecurring(), _reminder()];
  Map<String, dynamic> summary = _summary();
  List<Map<String, dynamic>> upcomingData = [
    _prodItem(status: 'upcoming', date: '2026-11-03'),
    _prodItem(status: 'upcoming', date: '2026-12-03', id: 'i-b'),
    _prodItem(status: 'upcoming', date: '2027-01-03', id: 'i-c', edited: true),
  ];
  List<Map<String, dynamic>> calendarData = [];
  bool networkDown = false;
  final calls = <String>[];
  final queries = <String>[];
  final writes = <Map<String, dynamic>>[];

  void _hit(String call) {
    calls.add(call);
    if (networkDown) throw _down;
  }

  @override
  Future<RecurringList> list({
    RecurringFilter filter = RecurringFilter.current,
    int page = 1,
    String q = '',
  }) async {
    queries.add(q);
    _hit('list:${filter.name}');
    return RecurringList(
      items: [for (final j in listData) Recurring.fromJson(j)],
      counts: const {'current': 2, 'archived': 0, 'all': 2},
      summary: RecurringSummary.fromJson(summary),
    );
  }

  @override
  Future<ItemPage> calendar(DateTime month) async {
    _hit('calendar:${month.year}-${month.month}');
    return ItemPage.fromJson({'data': calendarData, 'pagination': _page});
  }

  /// The BE's delete preview numbers (`?include=delete_preview`).
  Map<String, dynamic> preview = {
    'items': 4,
    'linked_transactions': 0,
    'pending_drafts': 1,
  };

  /// What an item write answers with: the owning setting (null = several).
  bool settingInWrites = true;

  Map<String, dynamic>? get _setting => settingInWrites
      ? {..._prodRecurring(), 'next_date': '2026-12-03', 'pending_count': 7}
      : null;

  @override
  Future<RecurringDetail> get(String id, {bool deletePreview = false}) async {
    _hit(deletePreview ? 'preview:$id' : 'get:$id');
    return RecurringDetail.fromJson({
      'upcoming': {'data': upcomingData, 'pagination': _page},
      ...detail,
      if (deletePreview) 'delete_preview': preview,
    });
  }

  @override
  Future<ItemPage> items(
    String recurringId, {
    required bool upcoming,
    int page = 1,
  }) async {
    _hit('items:${upcoming ? 'upcoming' : 'produced'}');
    return ItemPage.fromJson({
      'data': upcoming ? upcomingData : const [],
      'pagination': _page,
    });
  }

  @override
  Future<ItemWriteResult> editOccurrence(
    String id, {
    DateTime? date,
    double? amount,
  }) async {
    _hit('editOccurrence:$id');
    writes.add({'id': id, 'date': date, 'amount': amount});
    final base = upcomingData.firstWhere((j) => j['id'] == id);
    return ItemWriteResult.fromJson({
      'item': {...base, 'amount': amount ?? base['amount'], 'edited': true},
      'setting': _setting,
      'account_balances': const [],
    });
  }

  @override
  Future<ItemWriteResult> setItemArchived(
    String id, {
    required bool archived,
  }) async {
    _hit('${archived ? 'archive' : 'restore'}:$id');
    final base = upcomingData.firstWhere((j) => j['id'] == id);
    return ItemWriteResult.fromJson({
      'item': {...base, 'status': archived ? 'archived' : 'upcoming'},
      'setting': _setting,
      'account_balances': const [],
    });
  }
}

const _page = {'page': 1, 'per_page': 20, 'total': 1, 'total_pages': 1};

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
  'name': 'Internet',
  'type': 'expense',
  'icon_code': null,
  'is_system': false,
  'system_kind': null,
  'parent_id': null,
};

/// A recurring as `getRecurring` / `listRecurring` send it (0.4.0 shape).
Map<String, dynamic> _prodRecurring() => {
  'id': 'r1',
  'name': 'Netflix',
  'description': 'Family plan',
  'note': 'Shared with mom',
  'icon_code': null,
  'kind': 'subscription',
  'type': 'expense',
  'amount': 419,
  'trial_until': null,
  'yearly_cost': 5028,
  'monthly_amount': 838,
  'saved_count': 1,
  'pending_count': 2,
  'next_amount': 419,
  'current_occurrence': {
    'item_id': 'i-2026-11-03',
    'date': '2026-11-03',
    'days_until': 21,
    'amount': 419,
    'status': 'upcoming',
  },
  'account': _account(),
  'to_account': null,
  'category': _category(),
  'goal': null,
  'tags': [
    {'id': 't1', 'name': 'home', 'icon_code': null},
  ],
  'rule': {
    'freq': 'monthly',
    'interval': 1,
    'weekdays': <int>[],
    'monthly': {'mode': 'day', 'day': 3, 'nth': null, 'weekday': null},
    'dates': <String>[],
  },
  'start_date': '2026-10-03',
  'end': {'kind': 'count', 'date': null, 'count': 12},
  'status': 'active',
  'next_date': '2026-11-03',
  'days_until': 21,
  'progress': {'done': 1, 'total': 12},
  'ending_soon': false,
  'counts': {
    'upcoming': 11,
    'not_created': 0,
    'pending': 2,
    'done': 1,
    'archived': 0,
  },
  'edited_any': false,
  'actions': {
    'pause': true,
    'resume': false,
    'archive': true,
    'restore': false,
    'extend': false,
  },
  'created_at': '2026-10-01T08:00:00Z',
  'updated_at': '2026-10-03T08:00:00Z',
};

/// A reminder with no amount yet ("รอใส่ยอด").
Map<String, dynamic> _reminder() => {
  ..._prodRecurring(),
  'id': 'r2',
  'name': 'Water bill',
  'description': null,
  'note': null,
  'kind': 'reminder',
  'amount': null,
  'monthly_amount': null,
  'yearly_cost': 0,
  'saved_count': 0,
  'pending_count': 1,
  'next_amount': null,
  'current_occurrence': {
    'item_id': 'i-w',
    'date': '2026-10-15',
    'days_until': -2,
    'amount': null,
    'status': 'pending',
  },
  'end': {'kind': 'none', 'date': null, 'count': null},
  'progress': {'done': 0, 'total': null},
  'next_date': '2026-11-15',
};

Map<String, dynamic> _summary() => {
  'month_pay': 1234.5,
  'month_receive': 30000,
  'next': {
    'id': 'r1',
    'name': 'Netflix',
    'date': '2026-11-03',
    'amount': 419,
    'type': 'expense',
  },
  'due_30d_total': 6860,
  'awaiting_amount_count': 3,
  'by_kind': {
    'subscription': {'count': 1, 'monthly': 419, 'yearly': 5028},
    'installment': {'count': 0, 'monthly': 0, 'yearly': 0},
    'income': {'count': 0, 'monthly': 0, 'yearly': 0},
    'reminder': {'count': 1, 'monthly': 0, 'yearly': 0},
  },
};

Map<String, dynamic> _prodItem({
  String status = 'done',
  String date = '2026-10-03',
  String? id,
  bool edited = false,
  Object? amount = 419,
}) => {
  'id': id ?? 'i-$date',
  'recurring': {'id': 'r1', 'name': 'Netflix', 'icon_code': null},
  'seq': 1,
  'total': 12,
  'date': date,
  'days_until': -10,
  'status': status,
  'edited': edited,
  'manual': false,
  'type': 'expense',
  'amount': amount,
  'account': _account(),
  'to_account': null,
  'category': _category(),
  'tags': const [],
  'description': null,
  'note': null,
  'splits': const [],
  'project': null,
  'pending_id': null,
  'transaction': status == 'done'
      ? {'id': 'tx1', 'description': 'Netflix', 'account': _account()}
      : null,
  'created_at': '2026-10-01T08:00:00Z',
  'updated_at': '2026-10-03T08:00:00Z',
};

Map<String, dynamic> _prodDetail([Map<String, dynamic>? recurring]) => {
  'recurring': recurring ?? _prodRecurring(),
  'items': {
    'data': [_prodItem()],
    'pagination': _page,
  },
  'account_balances': [
    {'account_id': 'a1', 'balance': 1200.5},
  ],
};

void main() {
  late _Repo repo;
  late QuickCreateContext registry;

  setUp(() {
    ToolbarToggleState.resetAll();
    repo = _Repo();
    registry = QuickCreateContext();
  });

  tearDown(() => registry.dispose());

  Future<void> pump(WidgetTester t, Widget page) async {
    // A tall phone: the detail's pinned tab bar sits under hero + info + note.
    t.view.physicalSize = const Size(800, 2600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final accounts = _Accounts();
    final categories = _Categories();
    final tags = _Tags();
    final dashboard = _Dashboard();
    when(() => dashboard.state).thenReturn(const DashboardState());
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => tags.state).thenReturn(const TagsState());
    when(() => tags.loadIfNeeded()).thenAnswer((_) async {});
    await t.pumpWidget(
      RepositoryProvider<RecurringRepository>.value(
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

  Future<void> settle(WidgetTester t) async {
    await t.pumpAndSettle();
  }

  group('model', () {
    test('the rule round-trips through the API shape', () {
      final r = Recurring.fromJson(_prodRecurring());
      expect(r.rule.freq, RecurrenceFreq.monthly);
      expect(r.rule.monthly?.day, 3);
      expect(r.rule.end.count, 12);
      final json = recurrenceToJson(r.rule);
      expect(json['start_date'], '2026-10-03');
      expect(json['end'], {'kind': 'count', 'count': 12});
      expect(
        recurrenceFromJson(
          json['rule'] as Map<String, dynamic>,
          start: json['start_date'] as String,
          end: json['end'] as Map<String, dynamic>,
        ),
        r.rule,
      );
    });

    test('the 0.4.0 fields parse; a reminder has no amount', () {
      final r = Recurring.fromJson(_prodRecurring());
      expect(r.kind, RecurringKind.subscription);
      expect(r.yearlyCost, 5028);
      expect(r.savedCount, 1);
      expect(r.pendingCount, 2);
      expect(r.hasAmount, isTrue);
      final w = Recurring.fromJson(_reminder());
      expect(w.kind, RecurringKind.reminder);
      expect(w.amount, isNull);
      expect(w.hasAmount, isFalse);
      expect(w.currentOccurrence?.status, OccurrenceState.pending);
      expect(w.currentOccurrence?.amount, isNull);
    });

    test('the summary is the BE\'s: 30-day total, awaiting, by kind', () {
      final s = RecurringSummary.fromJson(_summary())!;
      expect(s.due30dTotal, 6860);
      expect(s.awaitingAmountCount, 3);
      expect(s.byKind[RecurringKind.subscription]?.yearly, 5028);
      expect(s.nextAmount, 419);
    });

    test('an item takes its state and link from the BE', () {
      final i = RecurringItem.fromJson(_prodItem());
      expect(i.state, OccurrenceState.done);
      expect(i.transaction?.id, 'tx1');
      expect(i.linked, isTrue);
      expect(i.title, 'Netflix');
      expect(RecurringItem.fromJson(_prodItem(amount: null)).amount, isNull);
    });

    test('the write: a reminder sends amount 0, a create leaves trial out', () {
      final draft = RecurringDraft.blank(
        preset: const RecurringPreset(kind: RecurringKind.reminder),
      ).copyWith(name: 'Water', accountId: 'a1');
      final body = draft.toWrite().toJson();
      expect(body['kind'], 'reminder');
      expect(body['amount'], 0);
      expect(body.containsKey('trial_until'), isFalse);
      // A PUT clears the trial with "".
      expect(draft.toWrite().toJson(forUpdate: true)['trial_until'], '');
    });

    test(
      'prefill: type / amount / category / name / account from the query',
      () {
        final p = RecurringPreset.fromQuery({
          'type': 'income',
          'amount': '30000',
          'category': 'c9',
          'name': 'Salary',
          'account': 'a1',
        });
        final d = RecurringDraft.blank(preset: p);
        // income → the รายรับ kind
        expect(d.kind, RecurringKind.income);
        expect(d.type, TransactionType.income);
        expect(d.name, 'Salary');
        expect(AmountInput.parse(d.amount), 30000);
        final body = d.toWrite().toJson();
        expect(body['category_id'], 'c9');
        expect(body['account_id'], 'a1');
        expect(body['type'], 'income');
      },
    );
  });

  group('list page', () {
    testWidgets('opens with ONE call; the card is the BE\'s', (t) async {
      await pump(t, const RecurringHomePage());
      expect(repo.calls, ['list:current']);
      expect(find.text('Netflix'), findsOneWidget);
      // The reminder lives on its own tab.
      expect(find.text('Water bill'), findsNothing);
      expect(find.text('Next 30 days to pay'), findsOneWidget);
      expect(find.textContaining('6,860'), findsOneWidget);
      expect(find.text('3 waiting for an amount'), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('card → tabs → rows, three swipe tabs', (t) async {
      await pump(t, const RecurringHomePage());
      final cardY = t.getTopLeft(find.byType(ListSummaryCard)).dy;
      final tabsY = t.getTopLeft(find.byType(AppTabBar<RecurringHomeTab>)).dy;
      final rowY = t.getTopLeft(find.text('Netflix')).dy;
      expect(cardY, lessThan(tabsY));
      expect(tabsY, lessThan(rowY));
      expect(find.text('Recurring'), findsWidgets);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
    });

    testWidgets('the amber alert goes to the reminder tab; no amount = words', (
      t,
    ) async {
      await pump(t, const RecurringHomePage());
      await t.tap(find.text('3 waiting for an amount'));
      await t.pumpAndSettle();
      expect(find.text('Water bill'), findsOneWidget);
      expect(find.text('No amount yet'), findsOneWidget);
      // Due already → its own group.
      expect(find.text('Due · in pending'), findsOneWidget);
    });

    testWidgets('the calendar loads its month the first time it shows', (
      t,
    ) async {
      final now = DateTime.now();
      final mm = now.month.toString().padLeft(2, '0');
      repo.calendarData = [
        _prodItem(
          status: 'upcoming',
          date: '${now.year}-$mm-${now.day.toString().padLeft(2, '0')}',
          id: 'i-cal',
        ),
      ];
      await pump(t, const RecurringHomePage());
      expect(repo.calls, ['list:current']);
      await t.tap(find.text('Calendar'));
      await t.pumpAndSettle();
      expect(repo.calls, ['list:current', 'calendar:${now.year}-${now.month}']);
      expect(find.byType(MonthCalendar), findsOneWidget);
      // Today is picked: its item is listed under the grid.
      expect(find.byKey(ValueKey('calendarDot:${now.day}')), findsOneWidget);
      expect(find.text('Netflix'), findsWidgets);
    });

    testWidgets('search sends q to the BE (one call per change)', (t) async {
      await pump(t, const RecurringHomePage());
      await t.tap(find.byType(ToolbarToggleButton));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'netf');
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.queries, ['', 'netf']);
      expect(find.text('Netflix'), findsOneWidget);
    });

    testWidgets('a failed reload keeps the rows and says so', (t) async {
      await pump(t, const RecurringHomePage());
      await t.tap(find.byType(ToolbarToggleButton));
      await t.pumpAndSettle();
      repo.networkDown = true;
      await t.enterText(find.byType(TextField), 'netf');
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Netflix'), findsOneWidget);
      expect(
        find.text('Refresh failed, showing the latest data'),
        findsOneWidget,
      );
    });

    testWidgets('?tab=upcoming opens on the calendar', (t) async {
      await pump(
        t,
        const RecurringHomePage(initialTab: RecurringHomeTab.calendar),
      );
      expect(repo.calls.first, 'list:current');
      expect(repo.calls.any((c) => c.startsWith('calendar:')), isTrue);
      expect(find.byType(MonthCalendar), findsOneWidget);
    });

    testWidgets('a paused recurring sits in its own group at the bottom', (
      t,
    ) async {
      repo.listData = [
        {..._prodRecurring(), 'status': 'paused'},
      ];
      await pump(t, const RecurringHomePage());
      expect(find.text('Paused'), findsWidgets);
      expect(find.text('Netflix'), findsOneWidget);
    });

    testWidgets('network down → error + retry', (t) async {
      repo.networkDown = true;
      await pump(t, const RecurringHomePage());
      expect(find.byType(ErrorView), findsOneWidget);
      repo.networkDown = false;
      await t.tap(find.text('Retry'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Netflix'), findsOneWidget);
    });
  });

  group('detail page', () {
    testWidgets('hero: kind chip, tiles, tags, info, note; ONE call', (
      t,
    ) async {
      await pump(t, const RecurringDetailPage(id: 'r1'));
      expect(repo.calls, ['get:r1']);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      // The BE's tiles.
      expect(find.text('Per year'), findsOneWidget);
      expect(find.textContaining('5,028'), findsWidgets);
      expect(find.text('Saved'), findsWidgets);
      expect(find.text('To confirm'), findsOneWidget);
      expect(find.text('2 times'), findsOneWidget);
      expect(find.text('home'), findsOneWidget);
      expect(find.text('Shared with mom'), findsOneWidget);
      expect(find.text('Family plan'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      // Past tab: the produced occurrence with its state.
      expect(find.byType(OccurrenceStateChip), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('upcoming: next card with actions + date chips', (t) async {
      await pump(t, const RecurringDetailPage(id: 'r1'));
      await t.tap(find.text('Upcoming'));
      await settle(t);
      // The first upcoming page rode along with the open call.
      expect(repo.calls, ['get:r1']);
      expect(find.byType(NextOccurrenceCard), findsOneWidget);
      expect(find.text('Edit amount'), findsOneWidget);
      expect(find.text('Move date'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.byType(OccurrenceDates), findsOneWidget);
      // The edited one is amber in the chips (amount in its label).
      expect(find.textContaining('419'), findsWidgets);
      expect(find.text('11 upcoming in total'), findsOneWidget);
    });

    testWidgets('แก้ยอด: ONE call, the answer patches the card', (t) async {
      await pump(t, const RecurringDetailPage(id: 'r1'));
      await t.tap(find.text('Upcoming'));
      await settle(t);
      await t.tap(find.text('Edit amount'));
      await t.pumpAndSettle();
      final field = find.descendant(
        of: find.byType(FormSheet),
        matching: find.byType(TextField),
      );
      await t.enterText(field.first, '500');
      await t.pump();
      await t.tap(
        find.descendant(
          of: find.byType(FormSheet),
          matching: find.text('Save'),
        ),
      );
      await t.pumpAndSettle();
      expect(repo.calls.where((c) => c.startsWith('editOccurrence')), [
        'editOccurrence:i-2026-11-03',
      ]);
      expect(repo.writes.single['amount'], 500);
      expect(repo.writes.single['date'], isNull);
      expect(find.text('Edited'), findsOneWidget);
    });

    testWidgets('hero ต่อเดือน = monthly_amount; info row = amount each time', (
      t,
    ) async {
      await pump(t, const RecurringDetailPage(id: 'r1'));
      expect(find.text('Per month'), findsOneWidget);
      expect(find.textContaining('838'), findsOneWidget);
      expect(find.text('Amount each time'), findsOneWidget);
      expect(find.textContaining('419'), findsWidgets);
    });

    testWidgets('an item write patches the setting: no re-read', (t) async {
      await pump(t, const RecurringDetailPage(id: 'r1'));
      await t.tap(find.text('Upcoming'));
      await settle(t);
      await t.tap(find.text('Skip'));
      await t.pumpAndSettle();
      await t.tap(find.text('Skip').last);
      await t.pumpAndSettle();
      expect(repo.calls, ['get:r1', 'archive:i-2026-11-03']);
      // The pending tile came from the write's `setting` (7 here).
      expect(find.text('7 times'), findsOneWidget);
    });

    testWidgets('a write with no setting re-runs the page call', (t) async {
      repo.settingInWrites = false;
      await pump(t, const RecurringDetailPage(id: 'r1'));
      await t.tap(find.text('Upcoming'));
      await settle(t);
      await t.tap(find.text('Skip'));
      await t.pumpAndSettle();
      await t.tap(find.text('Skip').last);
      await t.pumpAndSettle();
      expect(repo.calls, ['get:r1', 'archive:i-2026-11-03', 'get:r1']);
    });

    testWidgets('ข้าม: confirm, then ONE archive call', (t) async {
      await pump(t, const RecurringDetailPage(id: 'r1'));
      await t.tap(find.text('Upcoming'));
      await settle(t);
      await t.tap(find.text('Skip'));
      await t.pumpAndSettle();
      expect(find.text('Skip this occurrence?'), findsOneWidget);
      await t.tap(find.text('Skip').last);
      await t.pumpAndSettle();
      expect(repo.calls, contains('archive:i-2026-11-03'));
      // The skipped one left the upcoming list: the next one is the card.
      expect(find.byType(NextOccurrenceCard), findsOneWidget);
    });

    testWidgets('a reminder with no amount: "รอใส่ยอด" alert + ใส่ยอด action', (
      t,
    ) async {
      repo.detail = _prodDetail(_reminder());
      repo.upcomingData = [
        _prodItem(
          status: 'upcoming',
          date: '2026-11-15',
          id: 'i-w2',
          amount: null,
        ),
      ];
      await pump(t, const RecurringDetailPage(id: 'r2'));
      expect(find.text('Reminder'), findsOneWidget);
      // The big number and the amber alert say the amount is missing.
      expect(find.text('Enter amount'), findsOneWidget);
      expect(find.textContaining('Enter the amount'), findsOneWidget);
      await t.tap(find.text('Upcoming'));
      await settle(t);
      // Enter amount is the main action of the next card.
      expect(find.text('Enter amount'), findsWidgets);
      expect(find.text('Edit amount'), findsNothing);
    });

    testWidgets('network down → full-page error', (t) async {
      repo.networkDown = true;
      await pump(t, const RecurringDetailPage(id: 'r1'));
      expect(find.byType(ErrorView), findsOneWidget);
      expect(repo.calls, ['get:r1']);
    });

    testWidgets('a malformed body → error, not an endless skeleton', (t) async {
      repo.detail = {
        'recurring': {'name': 'x'},
      };
      await pump(t, const RecurringDetailPage(id: 'r1'));
      expect(find.byType(ErrorView), findsOneWidget);
    });
  });

  group('edit form', () {
    testWidgets('create: no call, opens in edit mode with 4 kind chips', (
      t,
    ) async {
      await pump(t, const RecurringDetailPage());
      expect(repo.calls, isEmpty);
      expect(find.text('New recurring'), findsOneWidget);
      expect(find.byType(ModeActionBar), findsOneWidget);
      for (final k in ['Subscription', 'Installment', 'Income', 'Reminder']) {
        expect(find.text(k), findsOneWidget);
      }
      // A subscription has a trial date, no payment count.
      expect(find.text('Free trial until'), findsOneWidget);
      expect(find.text('Number of payments'), findsNothing);
      expect(find.text('Amount / time'), findsOneWidget);
    });

    testWidgets('the kind chips switch the fields', (t) async {
      await pump(t, const RecurringDetailPage());
      await t.tap(find.text('Installment'));
      await t.pumpAndSettle();
      expect(find.text('Number of payments'), findsOneWidget);
      expect(find.text('Free trial until'), findsNothing);
      await t.tap(find.text('Reminder'));
      await t.pumpAndSettle();
      // The amount is optional; the hint says what happens on the day.
      expect(find.text('Amount / time (optional)'), findsOneWidget);
      expect(find.textContaining('No amount needed'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      await t.tap(find.text('Income'));
      await t.pumpAndSettle();
      expect(find.text('Into wallet'), findsOneWidget);
      expect(find.text('Amount / time'), findsOneWidget);
    });

    testWidgets('prefill from the query: name, amount, kind', (t) async {
      await pump(
        t,
        RecurringDetailPage(
          preset: RecurringPreset.fromQuery({
            'type': 'income',
            'amount': '30000',
            'name': 'Salary',
            'category': 'c1',
            'account': 'a1',
          }),
        ),
      );
      expect(repo.calls, isEmpty);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('30,000'), findsOneWidget);
      expect(find.text('Into wallet'), findsOneWidget);
    });

    testWidgets('edit mode of a saved one: end zone, no tabs, no tiles', (
      t,
    ) async {
      await pump(t, const RecurringDetailPage(id: 'r1', startEditing: true));
      expect(repo.calls, ['get:r1']);
      expect(find.byType(EndZone), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Delete recurring'), findsOneWidget);
      // Computed numbers and occurrences are hidden in edit mode.
      expect(find.text('Per year'), findsNothing);
      expect(find.text('Upcoming'), findsNothing);
      expect(find.byType(NextOccurrenceCard), findsNothing);
    });

    testWidgets('ลบ: ONE preview call, the dialog prints its numbers', (
      t,
    ) async {
      await pump(t, const RecurringDetailPage(id: 'r1', startEditing: true));
      await t.ensureVisible(find.text('Delete recurring'));
      await t.tap(find.text('Delete recurring'));
      await t.pumpAndSettle();
      expect(repo.calls, ['get:r1', 'preview:r1']);
      expect(
        find.text(
          'This deletes 4 occurrences, 1 waiting drafts and touches 0 saved '
          'records.',
        ),
        findsOneWidget,
      );
    });
  });
}
