import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/projects_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
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

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

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

/// Netflix, 3rd of 12, a recurring item's real transaction.
Map<String, dynamic> _row() => {
  'id': 't1',
  'type': 'expense',
  'account_id': 'a1',
  'account': _account,
  'amount': 419,
  'date': '2026-10-03',
  'description': 'Netflix',
  'tags': <Object>[],
  'recurring_item': {
    'item_id': 'i3',
    'recurring': {'id': 'r1', 'name': 'Netflix', 'icon_code': null},
    'seq': 3,
    'total': 12,
  },
};

/// GET /:id returns the row; PUT records `also_update_link` and answers
/// with the row — or, for a date after today, an upcoming item.
class _Repo extends Fake implements TransactionsRepository {
  final links = <bool?>[];

  /// Each delete's `skip_occurrence`.
  final deleteSkips = <bool?>[];
  bool upcoming = false;

  @override
  Future<DeleteTransactionResult> delete(
    String id, {
    bool? alsoDeleteLink,
    bool? skipOccurrence,
  }) async {
    deleteSkips.add(skipOccurrence);
    return DeleteTransactionResult.fromJson({
      'id': id,
      'account_balances': <Object>[],
      'recurring_item_id': 'i3',
    });
  }

  @override
  Future<Transaction> get(String id) async => Transaction.fromJson(_row());

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
    links.add(alsoUpdateLink);
    return TransactionWriteResult.fromJson({
      'rows': upcoming
          ? <Object>[]
          : [
              {..._row(), 'amount': amount},
            ],
      'account_balances': <Object>[],
      if (upcoming) 'upcoming': {'id': 'u1', 'date': '2026-11-03'},
    });
  }
}

/// Tx detail and its links (owner 2026-10-13): the 🔁 row, the save prompt
/// for a linked row (no sync), and a future date moving it to the upcoming
/// items.
void main() {
  late _Repo repo;
  late TransactionsCubit txs;

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester t) async {
    repo = _Repo();
    txs = TransactionsCubit(repository: repo);
    addTearDown(txs.close);
    final accounts = _Accounts();
    final tags = _Tags();
    final categories = _Categories();
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
    when(() => projects.state).thenReturn(const ProjectsState());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: 'u1', username: 'me', displayName: 'Me', currency: 'THB'),
      ),
    );
    // The detail page pushed over a home page, as in the app.
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
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<TransactionsCubit>.value(value: txs),
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<CategoriesCubit>.value(value: categories),
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

  Future<void> editAmountAndSave(WidgetTester t, String amount) async {
    final hero = t.widget<TransactionHeroCard>(
      find.byType(TransactionHeroCard),
    );
    hero.onEdit!();
    await settle(t);
    await t.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller == hero.amount,
      ),
      amount,
    );
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Save'));
    await settle(t);
  }

  testWidgets('the recurring row: "Netflix | 3/12"', (t) async {
    await pump(t);
    expect(find.text('Recurring'), findsOneWidget);
    expect(find.text('Netflix | 3/12'), findsOneWidget);
  });

  testWidgets('saving a linked row asks first; "Not now" sends nothing', (
    t,
  ) async {
    await pump(t);
    await editAmountAndSave(t, '450');
    expect(find.text('Update the other side too?'), findsOneWidget);
    await t.tap(find.text('Not now'));
    await settle(t);
    expect(repo.links, isEmpty);
  });

  testWidgets('"Save and update the other side" → also_update_link true', (
    t,
  ) async {
    await pump(t);
    await editAmountAndSave(t, '450');
    await t.tap(find.text('Save and update the other side'));
    await settle(t);
    expect(repo.links, [true]);
  });

  testWidgets('"Save this side only" → also_update_link false', (t) async {
    await pump(t);
    await editAmountAndSave(t, '450');
    await t.tap(find.text('Save this side only'));
    await settle(t);
    expect(repo.links, [false]);
  });

  Future<void> tapDelete(WidgetTester t) async {
    final hero = t.widget<TransactionHeroCard>(
      find.byType(TransactionHeroCard),
    );
    hero.onEdit!();
    await settle(t);
    // The list builds lazily: scroll the page down to the delete button,
    // then on past the bottom bar that overlaps the end of the list.
    final page = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    await t.scrollUntilVisible(
      find.text('Delete this transaction'),
      200,
      scrollable: page,
    );
    await t.drag(page, const Offset(0, -400));
    await settle(t);
    await t.tap(find.text('Delete this transaction'));
    await settle(t);
  }

  // A row recorded for a recurring occurrence asks about the occurrence
  // (owner rule: delete the tx only, or delete it and skip the occurrence).
  testWidgets('deleting a recurring row asks; "Cancel" deletes nothing', (
    t,
  ) async {
    await pump(t);
    await tapDelete(t);
    expect(find.text('Delete this transaction?'), findsOneWidget);
    expect(find.text('Linked to Netflix | 3/12'), findsOneWidget);
    // The dialog's Cancel (the page's edit bar has one too).
    await t.tap(find.text('Cancel').last);
    await settle(t);
    expect(repo.deleteSkips, isEmpty);
    expect(txs.byId('t1'), isNotNull);
  });

  testWidgets('"Delete and skip the occurrence" → skip_occurrence true', (
    t,
  ) async {
    await pump(t);
    await tapDelete(t);
    await t.tap(find.text('Delete and skip the occurrence'));
    await settle(t);
    expect(repo.deleteSkips, [true]);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('"Delete only" → skip_occurrence false', (t) async {
    await pump(t);
    await tapDelete(t);
    await t.tap(find.text('Delete only (the occurrence is due again)'));
    await settle(t);
    expect(repo.deleteSkips, [false]);
  });
}
