import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/pick_chip_rows.dart';
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

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Dashboard extends MockCubit<DashboardState> implements DashboardCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _TxRepo extends Fake implements TransactionsRepository {}

/// The debts API as the BE answers it; records the one create call.
class _DebtRepo extends Fake implements PersonalDebtsRepository {
  final created = <Map<String, Object?>>[];
  final repaid = <Map<String, Object?>>[];

  @override
  Future<DebtRepaymentResult> createRepayment(
    String key, {
    required DebtRepaymentKind kind,
    required double amount,
    required String accountId,
    DateTime? date,
    String? description,
    String? note,
    List<String>? tagIds,
    List<String>? markPaidIds,
    String? personName,
  }) async {
    repaid.add({
      'key': key,
      'kind': kind,
      'amount': amount,
      'account_id': accountId,
      'description': description,
      'mark_paid_ids': markPaidIds,
    });
    return DebtRepaymentResult(
      transaction: Transaction.fromJson(_txJson(amount)),
      balance: const PersonBalance(
        key: 'n:mom',
        person: EmbeddedPerson(name: 'Mom'),
        net: 0,
      ),
    );
  }

  @override
  Future<DebtEntryWriteResult> createEntry(
    String key, {
    required DebtEntryDirection direction,
    required double amount,
    DateTime? date,
    String? accountId,
    bool? createTransaction,
    String? description,
    String? note,
    List<String>? tagIds,
    List<String>? markPaidIds,
    String? personName,
  }) async {
    created.add({
      'key': key,
      'direction': direction,
      'amount': amount,
      'account_id': accountId,
      'create_transaction': createTransaction,
      'tag_ids': tagIds,
      'description': description,
    });
    return DebtEntryWriteResult(
      entry: DebtEntry(id: 'e1', direction: direction, amount: amount),
      balance: const PersonBalance(
        key: 'n:mom',
        person: EmbeddedPerson(name: 'Mom'),
        net: 300,
      ),
    );
  }
}

/// Quick create in DEBT MODE (owner 2026-10-12): a debt preset opens it with
/// the person; Paid / Received; the result line; ONE create call; the mode
/// chips switch to a normal transaction.
void main() {
  late _DebtRepo debts;
  late _Dashboard dashboard;
  DebtEntryWriteResult? saved;

  Future<void> open(
    WidgetTester t, {
    QuickCreatePreset? preset,
    Account? account,
  }) async {
    SharedPreferences.setMockInitialValues({});
    debts = _DebtRepo();
    dashboard = _Dashboard();
    saved = null;
    final accounts = _Accounts();
    final categories = _Categories();
    final tags = _Tags();
    final txs = _Txs();
    final auth = _Auth();
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => tags.state).thenReturn(const TagsState());
    when(() => txs.state).thenReturn(const TransactionsState());
    when(() => dashboard.state).thenReturn(const DashboardState());
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
          RepositoryProvider<PersonalDebtsRepository>.value(value: debts),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<TransactionsCubit>.value(value: txs),
            FakeTxFormOptions().provider,
            debtDirectoryProvider(_directoryWithMom()),
            BlocProvider<DashboardCubit>.value(value: dashboard),
            BlocProvider<AuthCubit>.value(value: auth),
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
                    preset: preset,
                    account: account,
                    onDebtSaved: (r) => saved = r,
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

  /// The EntryCard's amount field (the description sits left of it).
  Finder amountField(WidgetTester t) {
    final card = t.widget<EntryCard>(find.byType(EntryCard));
    return find.byWidgetPredicate(
      (w) => w is TextField && w.controller == card.amount,
    );
  }

  testWidgets('a debt preset opens debt mode on "record a debt" with the '
      'person; the debt words; money in a wallet OFF by default', (t) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    final chips = t.widget<QuickCreateModeTabs>(
      find.byType(QuickCreateModeTabs),
    );
    expect(chips.mode, QuickCreateMode.debt);
    // The value picker on top: record a debt | repay.
    expect(find.text('Record a debt'), findsOneWidget);
    expect(find.text('Repay'), findsOneWidget);
    final card = t.widget<EntryCard>(find.byType(EntryCard));
    expect(card.debt, isTrue);
    expect(card.repay, isFalse);
    // รอรับ / รอจ่าย (+ who pays whom back) replace Paid / Received.
    expect(find.text('To receive'), findsOneWidget);
    expect(find.text('To pay'), findsOneWidget);
    expect(find.text('they pay me back'), findsOneWidget);
    expect(find.text('I pay them back'), findsOneWidget);
    expect(find.text('Paid'), findsNothing);
    expect(find.text('Mom'), findsWidgets);
    expect(find.text('Money in / out of a wallet'), findsOneWidget);
    expect(find.byType(TagChipRow), findsNothing);
    // No "close debts" on this side any more.
    expect(find.text('Close debts'), findsNothing);
    expect(find.text('Mark as paid'), findsNothing);
    expect(find.byType(DraftForm), findsNothing);
    // The hint is per direction, never "what are they paying back".
    expect(card.titleHint, contains('paid for their lunch'));
  });

  testWidgets('the direction chips wear the DEBT-STATE colours: รอรับ '
      'green, รอจ่าย red; the card follows', (t) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    final ctx = t.element(find.byType(EntryCard));
    final green = debtStateColor(ctx, owedToMe: true);
    final red = debtStateColor(ctx, owedToMe: false);
    AppChip chip(String label) =>
        t.widget<AppChip>(find.widgetWithText(AppChip, label));
    expect(chip('To receive').color, green);
    expect(chip('To pay').color, red);
    expect(
      t.widget<TransactionHeroCard>(find.byType(TransactionHeroCard)).debt,
      isTrue,
    );
    expect(txWordsColor(ctx, TransactionType.expense, debt: true), green);
    // The repay side: รับคืน (they owed me) green, จ่ายคืน red.
    await t.tap(find.text('Repay'));
    await t.pumpAndSettle();
    expect(chip('Got back').color, green);
    expect(chip('Pay back').color, red);
  });

  testWidgets('the result line follows the amount and direction', (t) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    await t.enterText(amountField(t), '100');
    await t.pump();
    expect(find.textContaining('After saving: Mom owes you'), findsOneWidget);
    expect(find.textContaining('300'), findsWidgets);
    await t.tap(find.text('To pay'));
    await t.pump();
    expect(find.textContaining('100'), findsWidgets);
    expect(
      t.widget<EntryCard>(find.byType(EntryCard)).titleHint,
      contains('they paid for my lunch'),
    );
  });

  testWidgets('save = ONE create call, ledger only by default; the sheet '
      'closes; the answer goes to the caller', (t) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    await t.enterText(amountField(t), '100');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(debts.created, hasLength(1));
    expect(debts.repaid, isEmpty);
    final call = debts.created.single;
    expect(call['key'], 'n:mom');
    expect(call['direction'], DebtEntryDirection.paid);
    expect(call['amount'], 100);
    expect(call['account_id'], isNull);
    expect(call['create_transaction'], isFalse);
    expect(call['tag_ids'], isNull);
    expect(saved?.balance.net, 300);
    expect(find.byType(QuickCreateSheetShell), findsNothing);
  });

  testWidgets('switch ON = money moves: the tags show and a transaction is '
      'asked for', (t) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    await t.ensureVisible(find.text('Money in / out of a wallet'));
    await t.pumpAndSettle();
    await t.tap(find.text('Money in / out of a wallet'));
    await t.pump();
    expect(find.byType(TagChipRow), findsOneWidget);
    await t.enterText(amountField(t), '100');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    final call = debts.created.single;
    expect(call['create_transaction'], isTrue);
    expect(call['tag_ids'], isEmpty);
  });

  testWidgets('repay preset: the kind from the balance, the full open amount, '
      'a default description, "all cleared"; a wallet is required', (t) async {
    // Mom's balance is +200: she owes me, so this is "got back".
    await open(
      t,
      preset: const QuickCreatePreset.debt(
        person: EmbeddedPerson(name: 'Mom'),
        debtSub: DebtEntrySub.repay,
      ),
    );
    final card = t.widget<EntryCard>(find.byType(EntryCard));
    expect(card.repay, isTrue);
    expect(card.type, TransactionType.income);
    expect(find.text('Got back'), findsWidgets);
    expect(card.amount.text, '200');
    expect(card.title.text, 'Got back from Mom');
    expect(find.text('All cleared'), findsOneWidget);
    expect(find.text('Got back from'), findsOneWidget); // the person card
    expect(find.text('Mark as paid'), findsOneWidget);
    // No switch: a repayment always moves money.
    expect(find.text('Money in / out of a wallet'), findsNothing);
    expect(find.byType(TagChipRow), findsOneWidget);
    // A part: the line says what's left.
    await t.enterText(amountField(t), '150');
    await t.pump();
    expect(find.textContaining('50 left'), findsOneWidget);
    // No wallet → said, nothing sent.
    await t.tap(find.text('Save'));
    await t.pump();
    expect(debts.repaid, isEmpty);
    expect(find.byType(QuickCreateSheetShell), findsOneWidget);
  });

  testWidgets('repay save = ONE repayment call with the wallet; no debt row', (
    t,
  ) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(
        person: EmbeddedPerson(name: 'Mom'),
        debtSub: DebtEntrySub.repay,
        amount: 82,
      ),
      account: Account.fromJson(_walletJson),
    );
    // The preset amount (the person page's "รับคืนแล้ว ฿82") wins.
    expect(t.widget<EntryCard>(find.byType(EntryCard)).amount.text, '82');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(debts.created, isEmpty);
    expect(debts.repaid, hasLength(1));
    final call = debts.repaid.single;
    expect(call['key'], 'n:mom');
    expect(call['kind'], DebtRepaymentKind.receive);
    expect(call['amount'], 82);
    expect(call['account_id'], 'w1');
    expect(call['description'], 'Got back from Mom');
    expect(find.byType(QuickCreateSheetShell), findsNothing);
  });

  testWidgets('switching to repay and swapping the kind follows the words', (
    t,
  ) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    await t.tap(find.text('Repay'));
    await t.pumpAndSettle();
    var card = t.widget<EntryCard>(find.byType(EntryCard));
    expect(card.repay, isTrue);
    expect(card.title.text, 'Got back from Mom');
    // Switch the kind: the default description follows.
    await t.tap(find.text('Pay back').first);
    await t.pumpAndSettle();
    card = t.widget<EntryCard>(find.byType(EntryCard));
    expect(card.type, TransactionType.expense);
    expect(card.title.text, 'Paid back Mom');
    expect(find.text('Pay back to'), findsOneWidget);
  });

  testWidgets('no person → said, nothing sent', (t) async {
    await open(t);
    await t.tap(find.text('Debt'));
    await t.pumpAndSettle();
    await t.enterText(amountField(t), '50');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pump();
    expect(debts.created, isEmpty);
    expect(find.byType(QuickCreateSheetShell), findsOneWidget);
  });

  testWidgets('a plain + opens tx mode; the chips switch both ways, the '
      'amount comes along', (t) async {
    await open(t);
    expect(
      t.widget<QuickCreateModeTabs>(find.byType(QuickCreateModeTabs)).mode,
      QuickCreateMode.tx,
    );
    expect(find.byType(DraftForm), findsOneWidget);
    await t.enterText(amountField(t), '42');
    await t.tap(find.text('Debt'));
    await t.pumpAndSettle();
    expect(t.widget<EntryCard>(find.byType(EntryCard)).debt, isTrue);
    expect(find.text('42'), findsOneWidget);
    await t.tap(find.text('Transaction'));
    await t.pumpAndSettle();
    expect(find.byType(DraftForm), findsOneWidget);
  });
}

/// The repayment's ONE transaction as the BE sends it (income "Debt Received").
Map<String, dynamic> _txJson(double amount) => {
  'id': 't9',
  'account': {'id': 'w1', 'name': 'KBank'},
  'type': 'income',
  'amount': amount,
  'date': '2026-10-21',
};

const _walletJson = <String, dynamic>{
  'id': 'w1',
  'name': 'KBank',
  'type': 'bank',
  'group': 'asset',
  'balance': 1000,
  'currency': 'THB',
  'status': 'active',
  'my_role': 'owner',
  'track_balance': true,
};

DebtDirectoryCubit _directoryWithMom() {
  final directory = DebtDirectoryCubit(coordinator: testCoordinator());
  directory.applySync({
    'data': [
      {
        'key': 'n:mom',
        'person': {'name': 'Mom'},
        'net': 200,
        'open_count': 1,
        'entry_count': 1,
      },
    ],
    'totals': <String, dynamic>{},
    'pagination': {'page': 1, 'per_page': 1, 'total': 1, 'total_pages': 1},
  });
  return directory;
}
