import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/contacts/domain/contact.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/projects_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../shared/fake_sync.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Projects extends MockCubit<ProjectsState> implements ProjectsCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _ProjectsRepo extends Fake implements ProjectsRepository {}

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

Map<String, dynamic> _plain() => {
  'id': 't1',
  'type': 'expense',
  'account_id': 'a1',
  'account': _account,
  'amount': 419,
  'date': '2026-10-03',
  'description': 'Dinner',
  'tags': <Object>[],
  'link_mode': 'personal',
};

/// Lee paid 19 of my 419 dinner (B1).
Map<String, dynamic> _paid({String source = 'me'}) => {
  ..._plain(),
  'link_mode': 'paid',
  'wallet_amount': 400,
  'paid_by': {
    'debt_id': 'd1',
    'key': 'c:c2',
    'person': {'name': 'Lee', 'contact_id': 'c2'},
    'amount': 19,
    'my_paid': 400,
    'source': source,
    'paid': false,
  },
};

/// My bill on an event whose board was edited since (B3 in_sync false).
Map<String, dynamic> _outOfSync() => {
  ..._plain(),
  'link_mode': 'event',
  'event_bill': {
    'event': {'id': 'p1', 'name': 'Trip'},
    'bill_id': 'b1',
    'linked': true,
    'kind': 'origin',
    'in_sync': false,
    'differences': [
      {'field': 'amount', 'mine': 419, 'event': 450},
    ],
    'payer': {
      'id': 'm1',
      'user_id': 'u1',
      'name': 'Me',
      'icon_code': null,
      'is_me': true,
    },
    'bill_amount': 419,
    'members': <Object>[],
  },
};

final _lee = Contact.fromJson({
  'id': 'c2',
  'name': 'Lee',
  'display_name': 'Lee',
});

class _Repo extends Fake implements TransactionsRepository {
  Map<String, dynamic> Function() row = _plain;
  final updates = <Map<String, dynamic>?>[];
  final previews = <Map<String, dynamic>>[];
  int applied = 0;

  @override
  Future<Transaction> get(String id) async => Transaction.fromJson(row());

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
      'preview': true,
      'people': [
        {
          'key': 'c:c2',
          'person': {'name': 'Lee'},
          'before': 0,
          'after': -419,
          'delta': -419,
        },
      ],
      'wallets': [
        {'account_id': 'a1', 'before': 1000, 'after': 1419, 'delta': 419},
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
    return TransactionWriteResult.fromJson({
      'rows': [row()],
      'account_balances': <Object>[],
    });
  }

  @override
  Future<TransactionMutationResult> applyEvent(String id) async {
    applied++;
    return TransactionWriteResult.fromJson({
      'rows': [row()],
      'account_balances': <Object>[],
    });
  }
}

/// Editing a saved tx on the ผูกกับ tabs (0.4.0-3 B3): it opens on the saved
/// tab; a switch previews, ONE confirm lists who / which wallet moves, then
/// link_mode + the tab's data ride in the PUT. A partner's mirror and my copy
/// of someone else's bill have no tabs.
void main() {
  late _Repo repo;

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(
    WidgetTester t, {
    Map<String, dynamic> Function()? row,
  }) async {
    t.view.physicalSize = const Size(390 * 3, 2600 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    repo = _Repo();
    if (row != null) repo.row = row;
    final txs = TransactionsCubit(repository: repo);
    addTearDown(txs.close);
    final accounts = _Accounts();
    final tags = _Tags();
    final categories = _Categories();
    final contacts = _Contacts();
    final projects = _Projects();
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => tags.state).thenReturn(const TagsState());
    when(() => tags.loadIfNeeded()).thenAnswer((_) async {});
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => contacts.state).thenReturn(
      ContactsState(contacts: [_lee], status: ContactsStatus.loaded),
    );
    when(() => contacts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => projects.state).thenReturn(const ProjectsState());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
      ),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
          routes: [
            GoRoute(
              path: 'tx',
              builder: (_, _) => const Scaffold(
                body: TransactionDetailPage(transactionId: 't1'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TransactionsRepository>.value(value: repo),
          RepositoryProvider<ProjectsRepository>.value(value: _ProjectsRepo()),
          syncCoordinatorProvider(),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<TransactionsCubit>.value(value: txs),
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<ContactsCubit>.value(value: contacts),
            BlocProvider<ProjectsCubit>.value(value: projects),
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
          ],
          child: MaterialApp.router(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(child: child!),
            routerConfig: router,
          ),
        ),
      ),
    );
    await t.pump();
    router.push('/tx');
    await settle(t);
  }

  Future<void> edit(WidgetTester t) async {
    await t.tap(find.byIcon(AppIcons.edit).first, warnIfMissed: false);
    await settle(t);
  }

  final bar = find.byKey(const ValueKey('linkModeBar'));

  Future<void> tab(WidgetTester t, String label) async {
    await t.tap(find.descendant(of: bar, matching: find.text(label)));
    await settle(t);
  }

  LinkMode selectedTab(WidgetTester t) =>
      t.widget<LinkModeBar<LinkMode>>(bar).selected;

  Future<void> switchToPaidByLee(WidgetTester t) async {
    await edit(t);
    await tab(t, 'Paid for me');
    await t.tap(find.text('Pick who paid'));
    await settle(t);
    await t.tap(find.text('Lee').last);
    await settle(t);
  }

  testWidgets('edit opens on the saved tab', (t) async {
    await pump(t, row: _paid);
    await edit(t);
    expect(bar, findsOneWidget);
    expect(selectedTab(t), LinkMode.paid);
    expect(find.text('Lee'), findsWidgets);
  });

  testWidgets('ส่วนตัว → จ่ายแทน: preview, ONE confirm, then the PUT', (
    t,
  ) async {
    await pump(t);
    await switchToPaidByLee(t);
    await t.tap(find.text('Save').first);
    await settle(t);
    expect(repo.previews.single, {
      'link_mode': 'paid',
      'paid_by': {'contact_id': 'c2', 'amount': 419.0},
    });
    // The confirm lists who and which wallet move.
    expect(find.text('What will change'), findsOneWidget);
    expect(find.textContaining('Lee:'), findsOneWidget);
    expect(find.textContaining('KBank:'), findsOneWidget);
    expect(repo.updates, isEmpty);
    await t.tap(find.text('Save').last);
    await settle(t);
    expect(repo.updates.single, repo.previews.single);
  });

  testWidgets('cancelling the confirm saves nothing', (t) async {
    await pump(t);
    await switchToPaidByLee(t);
    await t.tap(find.text('Save').first);
    await settle(t);
    await t.tap(find.text('Cancel').last);
    await settle(t);
    expect(repo.updates, isEmpty);
  });

  testWidgets('a text edit on the same tab: no link_mode, no confirm', (
    t,
  ) async {
    await pump(t, row: _paid);
    await edit(t);
    final card = find.byType(TextField).first;
    await t.enterText(card, 'Dinner 2');
    await settle(t);
    await t.tap(find.text('Save').first);
    await settle(t);
    expect(repo.previews, isEmpty);
    expect(repo.updates, [null]);
  });

  testWidgets("a partner's mirror has no tabs", (t) async {
    await pump(t, row: () => _paid(source: 'partner'));
    await edit(t);
    expect(bar, findsNothing);
  });

  testWidgets('the bill changed on the board: "Update from the event"', (
    t,
  ) async {
    await pump(t, row: _outOfSync);
    final row = find.byKey(const ValueKey('linkViewApplyEvent'));
    expect(row, findsOneWidget);
    await t.tap(row);
    await settle(t);
    expect(repo.applied, 1);
    expect(find.text('Updated from the event'), findsOneWidget);
  });
}
