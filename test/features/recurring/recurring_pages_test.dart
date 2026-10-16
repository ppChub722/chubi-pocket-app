import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurrence_rule.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/recurring/presentation/pages/recurring_home_page.dart';
import 'package:chubi_pocket/features/recurring/presentation/pages/recurring_page.dart';
import 'package:chubi_pocket/features/recurring/presentation/pages/recurring_settings_page.dart';
import 'package:chubi_pocket/features/recurring/presentation/widgets/recurring_summary_card.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_summary.dart';
import 'package:chubi_pocket/features/recurring/presentation/recurring_rows.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
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

const _down = ApiException(code: 'NETWORK_ERROR', message: 'no connection');

/// Runs the REAL model parsing on prod-shaped bodies, or fails like the
/// network does.
class _Repo extends Fake implements RecurringRepository {
  Map<String, dynamic> detail = _prodDetail();
  bool networkDown = false;
  String listStatus = 'active';
  RecurringSummary? listSummary;
  final calls = <String>[];
  final queries = <String>[];

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
      items: [
        Recurring.fromJson({..._prodRecurring(), 'status': listStatus}),
      ],
      counts: const {'current': 1, 'archived': 0, 'all': 1},
      summary: listSummary,
    );
  }

  @override
  Future<ItemPage> upcoming({int page = 1}) async {
    _hit('upcoming');
    return ItemPage.fromJson({
      'data': [_prodItem(status: 'upcoming', date: '2026-11-03')],
      'pagination': _page,
    });
  }

  @override
  Future<RecurringDetail> get(String id) async {
    _hit('get:$id');
    return RecurringDetail.fromJson(detail);
  }

  @override
  Future<ItemPage> items(
    String recurringId, {
    required bool upcoming,
    int page = 1,
  }) async {
    _hit('items:${upcoming ? 'upcoming' : 'produced'}');
    return ItemPage.fromJson({'data': const [], 'pagination': _page});
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

/// A recurring as `getRecurring` sends it.
Map<String, dynamic> _prodRecurring() => {
  'id': 'r1',
  'name': 'Netflix',
  'description': 'Family plan',
  'note': null,
  'icon_code': null,
  'type': 'expense',
  'amount': 419,
  'account': _account(),
  'to_account': null,
  'category': _category(),
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
    'pending': 0,
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

Map<String, dynamic> _prodItem({
  String status = 'done',
  String date = '2026-10-03',
}) => {
  'id': 'i-$date',
  'recurring': {'id': 'r1', 'name': 'Netflix', 'icon_code': null},
  'seq': 1,
  'total': 12,
  'date': date,
  'days_until': -10,
  'status': status,
  'edited': false,
  'manual': false,
  'type': 'expense',
  'amount': 419,
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

Map<String, dynamic> _prodDetail() => {
  'recurring': _prodRecurring(),
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
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final accounts = _Accounts();
    final categories = _Categories();
    final tags = _Tags();
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

  group('ออม (saving)', () {
    Map<String, dynamic> savingJson() => {
      ..._prodRecurring(),
      'type': 'saving',
      'category': null,
      'tags': const [],
      'goal': {'id': 'g1', 'name': 'Japan trip', 'icon_code': null},
    };

    test('a saving recurring parses: flag + goal, no category', () {
      final r = Recurring.fromJson(savingJson());
      expect(r.isSaving, isTrue);
      expect(r.goal?.name, 'Japan trip');
      expect(r.category, isNull);
    });

    test('its write body is type saving + goal_id, no category / tags', () {
      final r = Recurring.fromJson(savingJson());
      final body = RecurringWrite(
        name: r.name,
        type: r.type,
        amount: r.amount,
        rule: r.rule,
        accountId: 'a1',
        categoryId: 'c1',
        tagIds: const ['t1'],
        isSaving: true,
        goalId: 'g1',
      ).toJson();
      expect(body['type'], 'saving');
      expect(body['goal_id'], 'g1');
      expect(body['category_id'], isNull);
      expect(body['tag_ids'], isEmpty);
    });

    test('spare = a saving with no goal (goal_id null on the wire)', () {
      final body = RecurringWrite(
        name: 'x',
        type: Recurring.fromJson(_prodRecurring()).type,
        amount: 100,
        rule: Recurring.fromJson(_prodRecurring()).rule,
        isSaving: true,
      ).toJson();
      expect(body.containsKey('goal_id'), isTrue);
      expect(body['goal_id'], isNull);
    });

    test('a saving item keeps its type through the entry-sheet draft', () {
      final i = RecurringItem.fromJson({
        ..._prodItem(status: 'pending'),
        'type': 'saving',
        'category': null,
        'goal': {'id': 'g1', 'name': 'Japan trip', 'icon_code': null},
      });
      expect(i.isSaving, isTrue);
      final draft = i.toDraft();
      expect(draft.isSaving, isTrue);
      expect(draft.goalId, 'g1');
      final fields = itemFieldsJson(draft);
      expect(fields['type'], 'saving');
      expect(fields['goal_id'], 'g1');
    });

    testWidgets('create preset: starts as ออม into the goal, no category', (
      t,
    ) async {
      await pump(t, const RecurringSettingsPage(saving: true, goalId: 'g1'));
      expect(repo.calls, isEmpty);
      expect(find.text('Saving'), findsWidgets);
      expect(find.text('From wallet'), findsOneWidget);
      expect(find.text('Save into'), findsOneWidget);
      expect(find.text('Category'), findsNothing);
    });
  });

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

    test('an item takes its state and link from the BE', () {
      final i = RecurringItem.fromJson(_prodItem());
      expect(i.state, OccurrenceState.done);
      expect(i.transaction?.id, 'tx1');
      expect(i.linked, isTrue);
      expect(i.title, 'Netflix');
    });
  });

  group('management page', () {
    testWidgets('opens with ONE call and lists the recurrings', (t) async {
      await pump(t, const RecurringHomePage());
      expect(repo.calls, ['list:current']);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('Debts list pattern: card → tabs → toolbar → rows', (t) async {
      await pump(t, const RecurringHomePage());
      await t.tap(find.byType(ToolbarToggleButton));
      await t.pumpAndSettle();
      final card = find.byType(RecurringSummaryCard);
      expect(card, findsOneWidget);
      // The card's own margin: inset from the screen edge.
      final box = find
          .descendant(of: card, matching: find.byType(Material))
          .first;
      expect(t.getTopLeft(box).dx, AppSpacing.lg);
      final cardY = t.getTopLeft(card).dy;
      final tabsY = t.getTopLeft(find.byType(AppTabBar<RecurringHomeTab>)).dy;
      final toolbarY = t.getTopLeft(find.byType(ListToolbar)).dy;
      final rowY = t.getTopLeft(find.byType(RecurringRow)).dy;
      expect(cardY, lessThan(tabsY));
      expect(tabsY, lessThan(toolbarY));
      expect(toolbarY, lessThan(rowY));
      // No summary in the response: the boxes show a dash, not a number.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('summary from the BE fills the card', (t) async {
      repo.listSummary = RecurringSummary.fromJson({
        'month_pay': 1234.5,
        'month_receive': 30000,
        'next': {
          'id': 'r1',
          'name': 'Netflix',
          'date': '2026-11-03',
          'amount': 419,
          'type': 'expense',
        },
      });
      await pump(t, const RecurringHomePage());
      expect(find.text('—'), findsNothing);
      expect(find.textContaining('1,234.50'), findsOneWidget);
      expect(find.textContaining('30,000.00'), findsOneWidget);
      expect(find.textContaining('Netflix'), findsWidgets);
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

    testWidgets('search toggle in the card; toolbar hidden; red dot', (
      t,
    ) async {
      await pump(t, const RecurringHomePage());
      final btn = find.byType(ToolbarToggleButton);
      expect(
        find.descendant(of: find.byType(RecurringSummaryCard), matching: btn),
        findsOneWidget,
      );
      CardActionButton button() => t.widget<CardActionButton>(
        find.descendant(of: btn, matching: find.byType(CardActionButton)),
      );
      expect(find.byType(TextField), findsNothing);
      expect(button().showDot, isFalse);
      await t.tap(btn);
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await t.enterText(find.byType(TextField), 'netf');
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(btn);
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(button().showDot, isTrue);
    });

    testWidgets('status dropdown chip shows the status and changes it', (
      t,
    ) async {
      await pump(t, const RecurringHomePage());
      await t.tap(find.byType(ToolbarToggleButton));
      await t.pumpAndSettle();
      expect(find.text('Status: Active'), findsOneWidget);
      await t.tap(find.text('Status: Active'));
      await t.pumpAndSettle();
      await t.tap(find.text('Archived').last);
      await t.pumpAndSettle();
      expect(repo.calls.last, 'list:archived');
      expect(find.text('Status: Archived'), findsOneWidget);
    });

    testWidgets('?tab=upcoming opens on the upcoming items', (t) async {
      await pump(
        t,
        const RecurringHomePage(initialTab: RecurringHomeTab.upcoming),
      );
      expect(repo.calls, ['upcoming']);
      expect(find.text('Netflix'), findsOneWidget);
    });

    testWidgets('a paused recurring stays in the default list', (t) async {
      repo.listStatus = 'paused';
      await pump(t, const RecurringHomePage());
      expect(repo.calls, ['list:current']);
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

  group('recurring page', () {
    testWidgets('prod-shaped detail: hero + produced items, one call', (
      t,
    ) async {
      await pump(t, const RecurringPage(id: 'r1'));
      expect(repo.calls, ['get:r1']);
      expect(find.text('Netflix'), findsWidgets);
      expect(find.byType(OccurrenceStateChip), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('network down → full-page error + retry', (t) async {
      repo.networkDown = true;
      await pump(t, const RecurringPage(id: 'r1'));
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('a malformed body → error, not an endless skeleton', (t) async {
      repo.detail = {
        'recurring': {'name': 'x'},
      };
      await pump(t, const RecurringPage(id: 'r1'));
      expect(find.byType(ErrorView), findsOneWidget);
    });
  });

  group('settings page', () {
    testWidgets('view: the setting, one call', (t) async {
      await pump(t, const RecurringSettingsPage(id: 'r1'));
      expect(repo.calls, ['get:r1']);
      expect(find.text('Netflix'), findsWidgets);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('create: no call, opens in edit mode', (t) async {
      await pump(t, const RecurringSettingsPage());
      expect(repo.calls, isEmpty);
      expect(find.text('New recurring'), findsOneWidget);
      expect(find.byType(ModeActionBar), findsOneWidget);
    });

    testWidgets('network down → full-page error', (t) async {
      repo.networkDown = true;
      await pump(t, const RecurringSettingsPage(id: 'r1'));
      expect(find.byType(ErrorView), findsOneWidget);
    });
  });
}
