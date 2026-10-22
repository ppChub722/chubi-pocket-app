import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/contacts/domain/contact.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/quick_create_sheet.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/fake_sync.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Dashboard extends MockCubit<DashboardState> implements DashboardCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Projects extends Fake implements ProjectsRepository {}

/// Records the create call's body parts.
class _TxRepo extends Fake implements TransactionsRepository {
  final created = <Map<String, Object?>>[];
  final updates = <Map<String, dynamic>?>[];
  final previews = <Map<String, dynamic>>[];

  @override
  Future<TxEditPreview> previewUpdate({
    required String id,
    double? amount,
    String? date,
    String? accountId,
    bool clearAccount = false,
    required Map<String, dynamic> link,
  }) async {
    previews.add(link);
    return TxEditPreview.fromJson({
      'people': [
        {
          'key': 'c:c2',
          'person': {'name': 'Lee'},
          'before': -19,
          'after': 0,
        },
      ],
      'wallets': [
        {'account_id': 'w1', 'before': 500, 'after': 481},
      ],
    });
  }

  @override
  Future<TransactionMutationResult> update({
    required String id,
    double? amount,
    String? date,
    String? categoryId,
    bool clearCategory = false,
    String? note,
    bool clearNote = false,
    String? description,
    bool clearDescription = false,
    String? accountId,
    bool clearAccount = false,
    String? transferToAccountId,
    List<String>? tagIds,
    bool? alsoUpdateLink,
    Map<String, dynamic>? link,
  }) async {
    updates.add(link);
    return TransactionMutationResult.single(
      Transaction.fromJson({
        'id': id,
        'type': 'expense',
        'amount': amount ?? 0,
        'date': date ?? '2026-10-21',
      }),
    );
  }

  @override
  Future<TransactionMutationResult> create({
    required TransactionType type,
    String? accountId,
    required double amount,
    required String date,
    String? categoryId,
    String? description,
    String? note,
    String? transferToAccountId,
    List<String> tagIds = const [],
    List<Map<String, dynamic>>? splits,
    String? sourceProjectTransactionId,
    Map<String, dynamic>? link,
  }) async {
    created.add({
      'type': type,
      'account_id': accountId,
      'amount': amount,
      'splits': splits,
      'link': link,
    });
    return TransactionMutationResult.single(
      Transaction.fromJson({
        'id': 'n1',
        'type': 'expense',
        'amount': amount,
        'date': date,
      }),
    );
  }

  @override
  Future<TransactionsPage> list({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? from,
    String? to,
    bool noWallet = false,
    String? q,
    List<String> tagIds = const [],
    bool includeChildren = false,
    bool uncategorized = false,
    List<String> accountIds = const [],
    List<String> categoryIds = const [],
    Set<TransactionType> types = const {},
    bool noTags = false,
    double? amountMin,
    double? amountMax,
    int page = 1,
    int perPage = 20,
    String sort = 'date_desc',
  }) async => const TransactionsPage(
    transactions: [],
    page: 1,
    perPage: 20,
    total: 0,
    totalPages: 1,
  );
}

final _wallet = Account.fromJson({
  'id': 'w1',
  'name': 'Cash',
  'type': 'cash',
  'balance': 500,
  'currency': 'THB',
});

final _lee = Contact.fromJson({
  'id': 'c2',
  'name': 'Lee',
  'display_name': 'Lee',
});

/// Quick create saves ONLY the active ผูกกับ tab (0.4.0-3 S4, B1 wire):
/// จ่ายแทน sends `paid_by` with the bill as `amount`, and no wallet when
/// they paid it all.
void main() {
  late _TxRepo repo;

  Future<void> open(WidgetTester t, {Transaction? edit}) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390 * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    repo = _TxRepo();
    final txs = TransactionsCubit(repository: repo);
    addTearDown(txs.close);
    final accounts = _Accounts();
    final categories = _Categories();
    final contacts = _Contacts();
    final tags = _Tags();
    final dashboard = _Dashboard();
    final auth = _Auth();
    when(() => accounts.state).thenReturn(AccountsState(accounts: [_wallet]));
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => contacts.state).thenReturn(
      ContactsState(contacts: [_lee], status: ContactsStatus.loaded),
    );
    when(() => tags.state).thenReturn(const TagsState());
    when(() => dashboard.state).thenReturn(const DashboardState());
    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
      ),
    );
    for (final loader in [
      accounts.loadIfNeeded,
      categories.loadIfNeeded,
      contacts.loadIfNeeded,
      tags.loadIfNeeded,
    ]) {
      when(loader).thenAnswer((_) async {});
    }
    when(() => accounts.patchBalances(any())).thenReturn(null);
    await t.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TransactionsRepository>.value(value: repo),
          RepositoryProvider<ProjectsRepository>.value(value: _Projects()),
          syncCoordinatorProvider(),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<ContactsCubit>.value(value: contacts),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<TransactionsCubit>.value(value: txs),
            FakeTxFormOptions().provider,
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
                    account: edit == null ? _wallet : null,
                    editTransaction: edit,
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
    await _settle(t);
  }

  Future<void> typeAmount(WidgetTester t, String v) async {
    final card = t.widget<EntryCard>(find.byType(EntryCard));
    await t.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller == card.amount,
      ),
      v,
    );
    await _settle(t);
  }

  Future<void> tab(WidgetTester t, String label) async {
    await t.tap(
      find.descendant(
        of: find.byKey(const ValueKey('linkModeBar')),
        matching: find.text(label),
      ),
    );
    await _settle(t);
  }

  Future<void> save(WidgetTester t) async {
    await t.tap(find.text('Save'));
    await _settle(t);
  }

  testWidgets('จ่ายแทน, they paid it all: paid_by = the bill, no wallet', (
    t,
  ) async {
    await open(t);
    await typeAmount(t, '123');
    await tab(t, 'Paid for me');
    await t.tap(find.text('Pick who paid'));
    await _settle(t);
    await t.tap(find.text('Lee').last);
    await _settle(t);
    expect(find.text('✓ Fully paid'), findsOneWidget);
    await save(t);
    expect(repo.created, hasLength(1));
    final body = repo.created.single;
    expect(body['amount'], 123);
    expect(body['account_id'], isNull);
    expect(body['splits'], isNull);
    expect(body['link'], {
      'paid_by': {'contact_id': 'c2', 'amount': 123.0},
    });
  });

  testWidgets('จ่ายแทน with no one picked: said, nothing sent', (t) async {
    await open(t);
    await typeAmount(t, '50');
    await tab(t, 'Paid for me');
    await save(t);
    expect(repo.created, isEmpty);
    expect(find.text('Pick who paid first'), findsOneWidget);
  });

  testWidgets('ส่วนตัว: a plain expense on the wallet', (t) async {
    await open(t);
    await typeAmount(t, '80');
    await save(t);
    final body = repo.created.single;
    expect(body['account_id'], 'w1');
    expect(body['splits'], isNull);
    expect(body['link'], isNull);
  });

  // ── edit in the sheet: the SAME form (owner, 0.4.0-3 B3) ───────────────
  /// Lee paid 19 of my 400 dinner, saved earlier.
  Transaction paidRow() => Transaction.fromJson({
    'id': 't9',
    'type': 'expense',
    'amount': 400,
    'date': '2026-10-21',
    'account': {'id': 'w1', 'name': 'Cash', 'type': 'cash'},
    'description': 'Dinner',
    'link_mode': 'paid',
    'wallet_amount': 381,
    'paid_by': {
      'debt_id': 'd1',
      'key': 'c:c2',
      'person': {'name': 'Lee', 'contact_id': 'c2'},
      'amount': 19,
      'my_paid': 381,
      'source': 'me',
      'paid': false,
    },
  });

  testWidgets('edit opens on the saved tab; จ่ายแทน → ส่วนตัว previews, '
      'confirms ONCE, then the PUT carries link_mode', (t) async {
    await open(t, edit: paidRow());
    final bar = find.byKey(const ValueKey('linkModeBar'));
    expect(bar, findsOneWidget);
    expect(find.byKey(const ValueKey('linkCardPaid')), findsOneWidget);
    await tab(t, 'Just me');
    await save(t);
    expect(repo.previews.single, {'link_mode': 'personal'});
    expect(find.text('What will change'), findsOneWidget);
    expect(find.textContaining('Lee:'), findsOneWidget);
    expect(find.textContaining('Cash:'), findsOneWidget);
    expect(repo.updates, isEmpty);
    await t.tap(find.text('Save').last);
    await _settle(t);
    expect(repo.updates.single, {'link_mode': 'personal'});
  });

  testWidgets('edit: cancelling the confirm saves nothing', (t) async {
    await open(t, edit: paidRow());
    await tab(t, 'Just me');
    await save(t);
    await t.tap(find.text('Cancel').last);
    await _settle(t);
    expect(repo.updates, isEmpty);
  });

  testWidgets('edit: a text change keeps the tab, no confirm, no link', (
    t,
  ) async {
    await open(t, edit: paidRow());
    final card = t.widget<EntryCard>(find.byType(EntryCard));
    await t.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller == card.title,
      ),
      'Dinner 2',
    );
    await _settle(t);
    await save(t);
    expect(repo.previews, isEmpty);
    expect(repo.updates, [null]);
  });
}

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}
