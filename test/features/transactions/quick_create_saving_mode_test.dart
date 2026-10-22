import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/data/saving_goals_repository.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_entry.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goals_overview.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/quick_create_sheet.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../shared/fake_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../saving_goals/saving_goal_parse_test.dart' show prodGoal, prodList;

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Dashboard extends MockCubit<DashboardState> implements DashboardCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Goals extends MockCubit<SavingGoalsState> implements SavingGoalsCubit {}

class _TxRepo extends Fake implements TransactionsRepository {}

/// The saving API; records the one write.
class _SavingRepo extends Fake implements SavingGoalsRepository {
  final writes = <Map<String, Object?>>[];

  @override
  Future<SavingGoalsOverview> list({
    String status = 'active',
    String sort = 'created',
  }) async => SavingGoalsOverview.fromJson(prodList());

  @override
  Future<SavingWriteResult> addEntry({
    required SavingEntryKind kind,
    required double amount,
    required String date,
    String? goalId,
    String? walletId,
    String? toGoalId,
    bool toSpare = false,
    List<SavingSplit>? splits,
    String? note,
  }) async {
    writes.add({
      'kind': kind,
      'amount': amount,
      'goal_id': goalId,
      'wallet_id': walletId,
      'note': note,
    });
    return SavingWriteResult.fromJson({
      'entries': <dynamic>[],
      'goals': [prodGoal()],
      'spare': prodList()['spare'],
      'wallets': <dynamic>[],
    });
  }
}

Account _wallet() => Account.fromJson({
  'id': 'w1',
  'name': 'KBank',
  'type': 'bank',
  'group': 'asset',
  'balance': 1000.0,
  'currency': 'THB',
  'icon_code': {'icon': 'bank', 'color': 'blue'},
  'status': 'active',
  'sort_order': 0,
  'my_role': 'owner',
  'can_edit': true,
  'is_shared': false,
  'track_balance': true,
  'savings': {
    'balance': 1000.0,
    'saved': 800.0,
    'spare': 200.0,
    'available': 200.0,
    'saved_exceeds_balance': false,
    'over_by': 0.0,
    'buckets': <dynamic>[],
  },
});

/// Quick create in ออม MODE (goals v2): the saving preset opens it with the
/// goal; the wallet's free amount shows; going over it warns but allows; ONE
/// call saves.
void main() {
  late _SavingRepo savings;
  late _Dashboard dashboard;
  late _Goals goals;
  late _Pending pending;

  Future<void> open(
    WidgetTester t, {
    QuickCreatePreset? preset,
    PendingTransaction? draft,
  }) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    savings = _SavingRepo();
    dashboard = _Dashboard();
    goals = _Goals();
    pending = _Pending();
    when(() => pending.state).thenReturn(const PendingState());
    final accounts = _Accounts();
    final categories = _Categories();
    final tags = _Tags();
    final txs = _Txs();
    final auth = _Auth();
    when(() => accounts.state).thenReturn(
      AccountsState(accounts: [_wallet()], status: AccountsStatus.loaded),
    );
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => tags.state).thenReturn(const TagsState());
    when(() => txs.state).thenReturn(const TransactionsState());
    when(() => dashboard.state).thenReturn(const DashboardState());
    when(() => goals.state).thenReturn(const SavingGoalsState());
    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
      ),
    );
    when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => tags.loadIfNeeded()).thenAnswer((_) async {});
    await t.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TransactionsRepository>.value(value: _TxRepo()),
          RepositoryProvider<SavingGoalsRepository>.value(value: savings),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<TransactionsCubit>.value(value: txs),
            FakeTxFormOptions().provider,
            BlocProvider<DashboardCubit>.value(value: dashboard),
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<SavingGoalsCubit>.value(value: goals),
            BlocProvider<PendingCubit>.value(value: pending),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showQuickCreateSheet(
                    context,
                    account: _wallet(),
                    preset: preset,
                    draft: draft,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  Finder amountField(WidgetTester t) {
    final card = t.widget<EntryCard>(find.byType(EntryCard));
    return find.byWidgetPredicate(
      (w) => w is TextField && w.controller == card.amount,
    );
  }

  testWidgets('the saving preset opens ออม mode with the goal chosen', (
    t,
  ) async {
    await open(t, preset: const QuickCreatePreset.saving(goalId: 'g1'));
    final chips = t.widget<QuickCreateModeTabs>(
      find.byType(QuickCreateModeTabs),
    );
    expect(chips.mode, QuickCreateMode.saving);
    // The goal row: the chosen goal (ยังไม่จัดสรร is only a picker card).
    expect(find.text('Not allocated'), findsNothing);
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
    // What the picked wallet still has free.
    expect(find.textContaining('200'), findsWidgets);
  });

  testWidgets('no goal chosen: "Pick a goal" opens the card picker with '
      'Not allocated first', (t) async {
    await open(t, preset: const QuickCreatePreset.saving());
    // The goal card reads "Not allocated" (the spare pool) until one is picked.
    expect(find.text('Not allocated'), findsOneWidget);
    await t.tap(find.text('Not allocated'));
    await t.pumpAndSettle();
    expect(find.byType(SavingGoalCard), findsWidgets);
    // The form's goal card and the picker's first card.
    expect(find.text('Not allocated'), findsNWidgets(2));
    await t.tap(find.text('ทริปญี่ปุ่น').last);
    await t.pumpAndSettle();
    expect(find.byType(SavingGoalCard), findsNothing);
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
  });

  testWidgets('over the free amount warns but still saves, ONE call', (
    t,
  ) async {
    await open(t, preset: const QuickCreatePreset.saving(goalId: 'g1'));
    await t.enterText(amountField(t), '500');
    await t.pumpAndSettle();
    expect(find.textContaining('more than is free'), findsOneWidget);
    await t.tap(find.text('Save').last);
    await t.pumpAndSettle();
    expect(savings.writes, hasLength(1));
    expect(savings.writes.single['kind'], SavingEntryKind.save);
    expect(savings.writes.single['amount'], 500);
    expect(savings.writes.single['goal_id'], 'g1');
    expect(savings.writes.single['wallet_id'], 'w1');
    expect(find.byType(QuickCreateSheetShell), findsNothing);
  });

  group('a pending 🐷 saving draft', () {
    PendingTransaction draft() => PendingTransaction.fromJson({
      'id': 'p1',
      'source': 'recurring',
      'kind': 'saving',
      'draft': {
        'type': 'saving',
        'amount': 150,
        'account_id': 'w1',
        'goal_id': 'g1',
        'date': '2026-10-13',
        'note': 'monthly',
      },
      'resolved': {
        'transfer_to_account': null,
        'category': null,
        'tags': <dynamic>[],
        'project': null,
        'splits': <dynamic>[],
        'goal': {'id': 'g1', 'name': 'ทริปญี่ปุ่น', 'icon_code': null},
        'missing': <dynamic>[],
      },
      'created_at': '2026-10-13T08:00:00Z',
      'updated_at': '2026-10-13T08:00:00Z',
    });

    setUpAll(() => registerFallbackValue(const PendingDraft()));

    testWidgets('opens the ออม form prefilled — nothing is confirmed yet', (
      t,
    ) async {
      await open(t, draft: draft());
      expect(find.byType(QuickCreateModeTabs), findsNothing);
      expect(find.text('Not allocated'), findsNothing);
      expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('monthly'), findsOneWidget);
      verifyNever(() => pending.submitOne(any()));
    });

    testWidgets('"confirm" saves the edits, then submits this draft', (
      t,
    ) async {
      await open(t, draft: draft());
      when(
        () => pending.updateDraft(any(), any()),
      ).thenAnswer((_) async => draft());
      when(() => pending.submitOne(any())).thenAnswer(
        (_) async => const PendingSubmitResult(submitted: ['p1'], failed: {}),
      );
      await t.enterText(amountField(t), '200');
      await t.pumpAndSettle();
      await t.tap(find.text('Confirm this one').last);
      await t.pumpAndSettle();
      final sent =
          verify(() => pending.updateDraft('p1', captureAny())).captured.single
              as PendingDraft;
      expect(sent.isSaving, isTrue);
      expect(sent.amount, 200);
      expect(sent.goalId, 'g1');
      expect(sent.accountId, 'w1');
      expect(sent.date, '2026-10-13');
      verify(() => pending.submitOne('p1')).called(1);
      expect(find.byType(QuickCreateSheetShell), findsNothing);
    });
  });
}
