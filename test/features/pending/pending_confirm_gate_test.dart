import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/data/pending_repository.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/pages/pending_page.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/form_options.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Dashboard extends MockCubit<DashboardState> implements DashboardCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Goals extends MockCubit<SavingGoalsState> implements SavingGoalsCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _TxRepo extends Fake implements TransactionsRepository {
  @override
  Future<TxFormOptions> formOptions() async => const TxFormOptions();
}

const _wallet = {
  'id': 'a1',
  'name': 'KBank',
  'icon_code': null,
  'logo_url': null,
  'type': 'bank',
  'group': 'asset',
  'currency': 'THB',
  'archived': false,
};

/// Prod-shaped draft (`needs_input` / `can_confirm` as BE 0.4.0 sends them).
Map<String, dynamic> draftJson(
  String id, {
  double? amount = 120,
  String source = 'manual',
  List<String>? needsInput,
  bool? canConfirm,
  String? description,
  Map<String, dynamic>? error,
}) => {
  'id': id,
  'source': source,
  'kind': 'create',
  'draft': {
    'type': 'expense',
    'amount': amount,
    'account_id': 'a1',
    'date': '2026-10-17',
    'description': description,
  },
  'resolved': {
    'account': _wallet,
    'transfer_to_account': null,
    'category': null,
    'tags': <dynamic>[],
    'project': null,
    'splits': <dynamic>[],
    'missing': <dynamic>[],
  },
  'target_debt_id': null,
  'target_transaction_id': null,
  'source_ref': null,
  'last_error': error,
  'needs_input': ?needsInput,
  'can_confirm': ?canConfirm,
  'created_at': '2026-10-17T08:00:00Z',
  'updated_at': '2026-10-17T08:00:00Z',
};

Map<String, dynamic> summaryJson({
  int count = 3,
  int manual = 2,
  int ready = 2,
  int needs = 1,
}) => {
  'count': count,
  'expense_total': 500.5,
  'income_total': 0,
  'needs_input_count': needs,
  'ready_count': ready,
  'by_source': {
    'recurring': count - manual,
    'manual': manual,
    'other_people': 0,
    'slip': 0,
    'other': 0,
  },
};

class _Repo extends Fake implements PendingRepository {
  _Repo(this.rows, {this.summary});
  List<PendingTransaction> rows;
  Map<String, dynamic>? summary;
  int listCalls = 0;
  final submitCalls = <List<String>>[];
  int submitReadyCalls = 0;
  final submitOneCalls = <String>[];
  Map<String, dynamic>? nextAnswer;

  @override
  Future<PendingList> list() async {
    listCalls++;
    return PendingList(
      items: rows,
      summary: summary == null ? null : PendingSummary.fromJson(summary!),
    );
  }

  /// What the BE answers after taking [ids] out: the summary over the rest.
  Map<String, dynamic> _summaryAfter(List<String> ids) {
    final left = rows.where((p) => !ids.contains(p.id)).length;
    return summaryJson(count: left, manual: left, ready: left, needs: 0);
  }

  PendingSubmitResult _answer(List<String> ids) => PendingSubmitResult.fromJson(
    nextAnswer ??
        {
          'summary': _summaryAfter(ids),
          'submitted': [
            for (final id in ids) {'id': id},
          ],
          'failed': <dynamic>[],
          'account_balances': <String, dynamic>{},
          'badges': {'pending_drafts': 0},
        },
  );

  @override
  Future<PendingSubmitResult> submit(List<String> ids) async {
    submitCalls.add(ids);
    return _answer(ids);
  }

  @override
  Future<PendingSubmitResult> submitReady() async {
    submitReadyCalls++;
    return _answer([
      for (final p in rows)
        if (p.needsInput?.isEmpty ?? true) p.id,
    ]);
  }

  @override
  Future<PendingSubmitResult> submitOne(String id) async {
    submitOneCalls.add(id);
    return _answer([id]);
  }
}

void main() {
  test('parses needs_input / can_confirm; absent = old behaviour', () {
    final p = PendingTransaction.fromJson(
      draftJson('p1', amount: null, needsInput: ['amount'], canConfirm: false),
    );
    expect(p.needsInput, ['amount']);
    expect(p.canConfirm, isFalse);
    expect(p.needs('amount'), isTrue);
    expect(p.needs('type'), isFalse);
    final old = PendingTransaction.fromJson(draftJson('p2'));
    expect(old.needsInput, isNull);
    expect(old.canConfirm, isTrue);
    expect(old.needs('amount'), isFalse);
  });

  test('parses summary (null-safe)', () {
    final s = PendingSummary.fromJson(summaryJson());
    expect(s.count, 3);
    expect(s.expenseTotal, 500.5);
    expect(s.readyCount, 2);
    expect(s.needsInputCount, 1);
    expect(s.manual, 2);
    expect(s.notManual, 1);
    expect(PendingSummary.fromJson(const {}).count, 0);
  });

  group('cubit', () {
    test('a write answer carries the summary; no second list call', () async {
      final repo = _Repo([
        PendingTransaction.fromJson(draftJson('p1')),
        PendingTransaction.fromJson(draftJson('p2')),
      ], summary: summaryJson(count: 2, manual: 2, ready: 2, needs: 0));
      final cubit = PendingCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.summary?.readyCount, 2);
      await cubit.submitOne('p1');
      expect(cubit.state.items.map((e) => e.id), ['p2']);
      // The numbers are the answer's, not the old load's, not row counts.
      expect(cubit.state.summary?.count, 1);
      expect(cubit.state.summary?.readyCount, 1);
      expect(repo.submitOneCalls, ['p1']);
      expect(repo.listCalls, 1);
      await cubit.close();
    });

    test('submitReady is ONE call; submitted leave the list', () async {
      final repo = _Repo([
        PendingTransaction.fromJson(draftJson('p1', needsInput: [])),
        PendingTransaction.fromJson(
          draftJson(
            'p2',
            amount: null,
            needsInput: ['amount'],
            canConfirm: false,
          ),
        ),
      ]);
      final cubit = PendingCubit(repository: repo);
      await cubit.load();
      final r = await cubit.submitReady();
      expect(repo.submitReadyCalls, 1);
      expect(repo.submitCalls, isEmpty);
      expect(r.submitted, ['p1']);
      expect(cubit.state.items.map((e) => e.id), ['p2']);
      await cubit.close();
    });

    test('a failed[] answer keeps the draft (server copy)', () async {
      final repo = _Repo([
        PendingTransaction.fromJson(
          draftJson(
            'p1',
            amount: null,
            needsInput: ['amount'],
            canConfirm: false,
          ),
        ),
      ]);
      repo.nextAnswer = {
        'submitted': <dynamic>[],
        'failed': [
          {
            'id': 'p1',
            'error': {'code': 'MISSING_AMOUNT', 'message': 'amount needed'},
            'pending': draftJson(
              'p1',
              amount: null,
              needsInput: ['amount'],
              canConfirm: false,
              error: {'code': 'MISSING_AMOUNT', 'message': 'amount needed'},
            ),
          },
        ],
        'account_balances': <String, dynamic>{},
        'badges': {'pending_drafts': 1},
      };
      final cubit = PendingCubit(repository: repo);
      await cubit.load();
      final r = await cubit.submitOne('p1');
      expect(r.failed.keys, ['p1']);
      expect(cubit.state.items.single.id, 'p1');
      expect(cubit.state.items.single.lastError?.code, 'MISSING_AMOUNT');
      await cubit.close();
    });
  });

  group('page', () {
    late _Repo repo;
    late PendingCubit pending;

    Future<void> pump(WidgetTester t, _Repo r) async {
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = const Size(800, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      repo = r;
      pending = PendingCubit(repository: repo);
      addTearDown(pending.close);
      final accounts = _Accounts();
      final categories = _Categories();
      final tags = _Tags();
      final txs = _Txs();
      final dashboard = _Dashboard();
      final goals = _Goals();
      final auth = _Auth();
      final unread = _Unread();
      when(() => accounts.state).thenReturn(const AccountsState());
      when(() => categories.state).thenReturn(const CategoriesState());
      when(() => tags.state).thenReturn(const TagsState());
      when(() => txs.state).thenReturn(const TransactionsState());
      when(() => dashboard.state).thenReturn(const DashboardState());
      when(() => goals.state).thenReturn(const SavingGoalsState());
      when(() => unread.state).thenReturn(0);
      when(() => auth.state).thenReturn(
        const AuthAuthenticated(
          User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
        ),
      );
      when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
      when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
      when(() => tags.loadIfNeeded()).thenAnswer((_) async {});
      final registry = QuickCreateContext();
      addTearDown(registry.dispose);
      await t.pumpWidget(
        RepositoryProvider<TransactionsRepository>.value(
          value: _TxRepo(),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AccountsCubit>.value(value: accounts),
              BlocProvider<CategoriesCubit>.value(value: categories),
              BlocProvider<TagsCubit>.value(value: tags),
              BlocProvider<TransactionsCubit>.value(value: txs),
              BlocProvider<DashboardCubit>.value(value: dashboard),
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<SavingGoalsCubit>.value(value: goals),
              BlocProvider<UnreadBadgeCubit>.value(value: unread),
              BlocProvider<PendingCubit>.value(value: pending),
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
                child: QuickCreateContextScope(
                  registry: registry,
                  child: child!,
                ),
              ),
              home: const PendingPage(),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
    }

    testWidgets('opens with ONE call; filter chips come from the summary', (
      t,
    ) async {
      await pump(
        t,
        _Repo([
          PendingTransaction.fromJson(draftJson('p1', description: 'Lunch')),
          PendingTransaction.fromJson(draftJson('p2', description: 'Taxi')),
          PendingTransaction.fromJson(
            draftJson(
              'p3',
              source: 'recurring',
              amount: null,
              needsInput: ['amount'],
              canConfirm: false,
              description: 'Rent reminder',
            ),
          ),
        ], summary: summaryJson()),
      );
      expect(repo.listCalls, 1);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('All 3'), findsOneWidget);
      expect(find.text('Mine 2'), findsOneWidget);
      expect(find.text('From others 1'), findsOneWidget);
    });

    testWidgets('an amount-less reminder cannot be confirmed from the list: '
        'it opens the sheet and nothing is sent', (t) async {
      await pump(
        t,
        _Repo([
          PendingTransaction.fromJson(
            draftJson(
              'p3',
              source: 'recurring',
              amount: null,
              needsInput: ['amount'],
              canConfirm: false,
              description: 'Rent reminder',
            ),
          ),
        ], summary: summaryJson(count: 1, manual: 0, ready: 0, needs: 1)),
      );
      // The row says what is missing (from needs_input).
      expect(find.text('Enter an amount before confirming'), findsWidgets);
      await t.tap(find.byType(SelectCheck).first);
      await t.pump();
      await t.tap(find.text('Confirm selected (1)'));
      await t.pumpAndSettle();
      expect(repo.submitCalls, isEmpty);
      expect(repo.submitReadyCalls, 0);
      expect(find.byType(QuickCreateSheetShell), findsOneWidget);
    });

    testWidgets('a mixed selection sends only the ones that can go, in one '
        'call', (t) async {
      await pump(
        t,
        _Repo([
          PendingTransaction.fromJson(draftJson('p1', description: 'Lunch')),
          PendingTransaction.fromJson(
            draftJson(
              'p3',
              amount: null,
              needsInput: ['amount'],
              canConfirm: false,
              description: 'Rent reminder',
            ),
          ),
        ], summary: summaryJson(count: 2, manual: 2, ready: 1, needs: 1)),
      );
      await t.tap(find.byType(SelectCheck).first); // select all
      await t.pump();
      await t.tap(find.text('Confirm selected (2)'));
      await t.pumpAndSettle();
      expect(repo.submitCalls, [
        ['p1'],
      ]);
      expect(pending.state.items.map((e) => e.id), ['p3']);
      // The numbers came with the submit answer; the list is not re-read.
      expect(repo.listCalls, 1);
      expect(pending.state.summary?.count, 1);
    });
  });
}
