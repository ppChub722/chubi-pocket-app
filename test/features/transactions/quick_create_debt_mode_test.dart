import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/form_options.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Dashboard extends MockCubit<DashboardState> implements DashboardCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _TxRepo extends Fake implements TransactionsRepository {
  @override
  Future<TxFormOptions> formOptions() async => const TxFormOptions();
}

const _mom = PersonBalance(
  key: 'n:mom',
  person: EmbeddedPerson(name: 'Mom'),
  net: 200,
  openCount: 1,
);

/// The debts API as the BE answers it; records the one create call.
class _DebtRepo extends Fake implements PersonalDebtsRepository {
  final created = <Map<String, Object?>>[];

  @override
  Future<DebtPeoplePage> listPeople({
    int page = 1,
    int perPage = 30,
    String? q,
    bool all = false,
    NetSide? side,
    DebtPeopleSort sort = DebtPeopleSort.oldest,
  }) async => const DebtPeoplePage(
    items: [_mom],
    totals: DebtTotals(owedToMe: 200, net: 200, openCount: 1),
    paging: DebtPaging(total: 1),
  );

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

  Future<void> open(WidgetTester t, {QuickCreatePreset? preset}) async {
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

  testWidgets('a debt preset opens debt mode with the person', (t) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    final chips = t.widget<QuickCreateModeTabs>(
      find.byType(QuickCreateModeTabs),
    );
    expect(chips.mode, QuickCreateMode.debt);
    expect(t.widget<EntryCard>(find.byType(EntryCard)).debt, isTrue);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('Mom'), findsWidgets);
    // No "no wallet" chip: not choosing one is no wallet. The switch is on
    // by default, so the wallet row and the tags are there.
    expect(find.text('No wallet'), findsNothing);
    expect(find.text('Also create a transaction'), findsOneWidget);
    expect(find.byType(TagChipRow), findsOneWidget);
    expect(find.text('Close debts'), findsOneWidget);
    expect(find.byType(DraftForm), findsNothing);
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
    await t.tap(find.text('Received'));
    await t.pump();
    expect(find.textContaining('100'), findsWidgets);
  });

  testWidgets('save = ONE create call; the sheet closes; the answer goes '
      'to the caller', (t) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    await t.enterText(amountField(t), '100');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(debts.created, hasLength(1));
    final call = debts.created.single;
    expect(call['key'], 'n:mom');
    expect(call['direction'], DebtEntryDirection.paid);
    expect(call['amount'], 100);
    expect(call['account_id'], isNull);
    // A transaction is written even with no wallet (the default).
    expect(call['create_transaction'], isTrue);
    expect(call['tag_ids'], isEmpty);
    expect(saved?.balance.net, 300);
    expect(find.byType(QuickCreateSheetShell), findsNothing);
    verify(() => dashboard.markStale()).called(1);
  });

  testWidgets('switch off = ledger only: no wallet row, no tags, nothing of '
      'them sent', (t) async {
    await open(
      t,
      preset: const QuickCreatePreset.debt(person: EmbeddedPerson(name: 'Mom')),
    );
    await t.ensureVisible(find.text('Also create a transaction'));
    await t.pumpAndSettle();
    await t.tap(find.text('Also create a transaction'));
    await t.pump();
    expect(find.byType(TagChipRow), findsNothing);
    expect(find.byType(WalletChipRow), findsNothing);
    await t.enterText(amountField(t), '100');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    final call = debts.created.single;
    expect(call['create_transaction'], isFalse);
    expect(call['account_id'], isNull);
    expect(call['tag_ids'], isNull);
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
