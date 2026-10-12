import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/home/presentation/cubit/dashboard_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/projects_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/pages/debt_entry_detail_page.dart';
import 'package:chubi_pocket/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Projects extends MockCubit<ProjectsState> implements ProjectsCubit {}

class _ProjectsRepo extends Fake implements ProjectsRepository {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Dashboard extends MockCubit<DashboardState> implements DashboardCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

const _account = {
  'id': 'a1',
  'name': 'KBank',
  'icon_code': null,
  'logo_url': null,
  'type': 'bank',
  'group': 'asset',
  'currency': 'THB',
  'archived': false,
};

const _person = {
  'name': 'Mom',
  'contact_id': null,
  'icon_code': null,
  'linked': false,
  'linked_user_id': null,
};

/// GET /personal-debts/{id} as the BE sends it: I paid Mom ฿200 from KBank;
/// she owes me ฿200 overall.
Map<String, dynamic> _detail({bool withWallet = true}) => {
  'entry': {
    'id': 'e1',
    'key': 'n:mom',
    'direction': 'paid',
    'amount': 200,
    'date': '2026-10-12',
    'description': 'Lunch money',
    'note': null,
    'paid': false,
    'source': null,
    'transaction': withWallet ? {'id': 't1', 'account': _account} : null,
    'created_at': '2026-10-12T09:30:00Z',
    'updated_at': '2026-10-12T09:30:00Z',
  },
  'person_balance': {
    'key': 'n:mom',
    'person': _person,
    'net': 200,
    'open_count': 1,
    'entry_count': 1,
    'last_activity_at': '2026-10-12',
  },
  'transaction': withWallet ? _tx() : null,
};

Map<String, dynamic> _tx() => {
  'id': 't1',
  'type': 'expense',
  'account_id': 'a1',
  'account': _account,
  'amount': 200,
  'date': '2026-10-12',
  'description': 'Lunch money',
  'tags': <Object>[],
  'counterparty': {
    'entry_id': 'e1',
    'key': 'n:mom',
    'person': _person,
    'direction': 'paid',
    'paid': false,
  },
};

class _Repo extends Fake implements PersonalDebtsRepository {
  Map<String, dynamic> body = _detail();
  bool down = false;
  int gets = 0;
  final updates = <DebtEntryUpdate>[];
  final deletes = <String>[];

  @override
  Future<DebtEntryDetail> getEntry(String id) async {
    gets++;
    if (down) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no net');
    }
    return DebtEntryDetail.fromJson(body);
  }

  @override
  Future<DebtEntryWriteResult> updateEntry(
    String id,
    DebtEntryUpdate update,
  ) async {
    updates.add(update);
    return DebtEntryWriteResult.fromJson({
      'entry': {...body['entry'] as Map<String, dynamic>, 'amount': 250},
      'person_balance': {
        ...body['person_balance'] as Map<String, dynamic>,
        'net': 250,
      },
      'previous_person_balance': null,
      'transaction': body['transaction'],
      'account_balances': [
        {'account_id': 'a1', 'balance': 750},
      ],
    });
  }

  @override
  Future<DebtEntryDeleteResult> deleteEntry(String id) async {
    deletes.add(id);
    return DebtEntryDeleteResult.fromJson({
      'id': id,
      'transaction_id': 't1',
      'person_balance': {
        ...body['person_balance'] as Map<String, dynamic>,
        'net': 0,
      },
      'account_balances': [
        {'account_id': 'a1', 'balance': 1000},
      ],
    });
  }
}

/// The transaction detail page in debt mode (owner 2026-10-12): one GET,
/// Paid / Received + the person card + the wallet card; edits are ONE PUT;
/// delete names the debt and the wallet tx and takes both; a tx row that is
/// an entry's wallet side opens here.
void main() {
  late _Repo repo;
  late _Txs txs;
  late _Accounts accounts;
  late _Dashboard dashboard;

  setUp(() {
    repo = _Repo();
    txs = _Txs();
    accounts = _Accounts();
    dashboard = _Dashboard();
  });

  /// Edit mode keeps a shimmer running (the tag row loads): pump a while
  /// instead of settling.
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester t, Widget page) async {
    final tags = _Tags();
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final categories = _Categories();
    final projects = _Projects();
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => projects.state).thenReturn(const ProjectsState());
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => tags.state).thenReturn(const TagsState());
    when(() => tags.loadIfNeeded()).thenAnswer((_) async {});
    when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => txs.state).thenReturn(const TransactionsState());
    when(() => dashboard.state).thenReturn(const DashboardState());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
      ),
    );
    await t.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<PersonalDebtsRepository>.value(value: repo),
          RepositoryProvider<ProjectsRepository>.value(value: _ProjectsRepo()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<ProjectsCubit>.value(value: projects),
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<TransactionsCubit>.value(value: txs),
            BlocProvider<DashboardCubit>.value(value: dashboard),
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(child: child!),
            // Like the shell: a Scaffold under the root messenger (the
            // "deleted" snackbar outlives the page).
            home: Scaffold(body: page),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('one GET; Paid / Received, the person and wallet cards, the '
      'balance now', (t) async {
    await pump(t, const DebtEntryDetailPage(entryId: 'e1'));
    expect(repo.gets, 1);
    final hero = t.widget<TxHeroCard>(find.byType(TxHeroCard));
    expect(hero.debt, isTrue);
    // The type chip (and the paid-label row).
    expect(find.text('Paid'), findsWidgets);
    expect(find.text('Received'), findsNothing);
    expect(find.text('Mom'), findsWidgets);
    expect(find.text('KBank'), findsWidgets);
    expect(find.textContaining('Now: Mom owes you'), findsOneWidget);
  });

  testWidgets('a ledger-only entry: the wallet card says no wallet', (t) async {
    repo.body = _detail(withWallet: false);
    await pump(t, const DebtEntryDetailPage(entryId: 'e1'));
    expect(find.text('No wallet'), findsWidgets);
  });

  testWidgets('a failed load: error + retry; retry loads', (t) async {
    repo.down = true;
    await pump(t, const DebtEntryDetailPage(entryId: 'e1'));
    expect(find.byType(ErrorView), findsOneWidget);
    repo.down = false;
    await t.tap(find.text('Retry'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(TxHeroCard), findsOneWidget);
  });

  testWidgets('edit the amount → ONE PUT with only the amount; caches '
      'patched from the answer', (t) async {
    await pump(t, const DebtEntryDetailPage(entryId: 'e1'));
    final hero = t.widget<TxHeroCard>(find.byType(TxHeroCard));
    hero.onEdit!();
    await settle(t);
    await t.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller == hero.amount,
      ),
      '250',
    );
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Save'));
    await settle(t);
    expect(repo.updates, hasLength(1));
    final u = repo.updates.single;
    expect(u.amount, 250);
    expect(u.direction, isNull);
    expect(u.description, isNull);
    expect(u.key, isNull);
    verify(() => accounts.patchBalances({'a1': 750})).called(1);
    verify(() => dashboard.markStale()).called(1);
  });

  testWidgets('delete names the wallet tx too, then takes both', (t) async {
    await pump(t, const DebtEntryDetailPage(entryId: 'e1'));
    t.widget<TxHeroCard>(find.byType(TxHeroCard)).onEdit!();
    await settle(t);
    await t.scrollUntilVisible(
      find.text('Delete this entry'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Delete this entry'));
    await settle(t);
    expect(find.textContaining('“KBank” goes too'), findsOneWidget);
    await t.tap(find.text('Delete').last);
    await settle(t);
    expect(repo.deletes, ['e1']);
    verify(() => txs.dropRow('t1')).called(1);
    verify(() => accounts.patchBalances({'a1': 1000})).called(1);
  });

  testWidgets('a tx row that is an entry’s wallet side opens in debt '
      'mode, with no plain GET first', (t) async {
    final row = Transaction.fromJson(_tx());
    when(() => txs.byId('t1')).thenReturn(row);
    await pump(t, const TransactionDetailPage(transactionId: 't1'));
    expect(find.byType(DebtEntryDetailPage), findsOneWidget);
    verifyNever(() => txs.refreshOne(any()));
    expect(repo.gets, 1);
  });

  testWidgets(
    'a row in an event: the event row names it; no auto-sync hint (owner 2026-10-13: linked by prompt)',
    (t) async {
      final row = Transaction.fromJson({
        ..._tx(),
        'counterparty': null,
        'category': null,
        'event_bill': {
          'event': {
            'id': 'p1',
            'name': 'Trip',
            'icon_code': null,
            'status': 'active',
          },
          'bill_id': 'b1',
          'linked': true,
        },
      });
      expect(row.eventBill?.billId, 'b1');
      expect(row.eventBill?.linked, isTrue);
      when(() => txs.byId('t1')).thenReturn(row);
      when(() => txs.refreshOne(any())).thenAnswer((_) async => row);
      await pump(t, const TransactionDetailPage(transactionId: 't1'));
      expect(find.text('Trip'), findsWidgets);
      expect(find.byType(LinkedFieldHint), findsNothing);
      t.widget<TxHeroCard>(find.byType(TxHeroCard)).onEdit!();
      await settle(t);
      expect(find.byType(LinkedFieldHint), findsNothing);
      expect(find.text('Trip'), findsWidgets);
    },
  );
}
