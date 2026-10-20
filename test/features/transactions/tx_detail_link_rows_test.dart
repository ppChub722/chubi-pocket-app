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

import '../../shared/fake_sync.dart';

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

/// A plain own expense: nothing split, no event, no recurring.
Map<String, dynamic> _row() => {
  'id': 't1',
  'type': 'expense',
  'account_id': 'a1',
  'account': _account,
  'amount': 419,
  'date': '2026-10-03',
  'description': 'Netflix',
  'tags': <Object>[],
};

/// GET /:id returns the row; PUT records `also_update_link` and answers
/// with the row — or, for a date after today, an upcoming item.
class _Repo extends Fake implements TransactionsRepository {
  final links = <bool?>[];
  final deleteLinks = <bool?>[];
  bool upcoming = false;

  @override
  Future<DeleteTransactionResult> delete(
    String id, {
    bool? alsoDeleteLink,
    bool? skipOccurrence,
  }) async {
    deleteLinks.add(alsoDeleteLink);
    return DeleteTransactionResult.fromJson({
      'id': id,
      'account_balances': <Object>[],
      if (alsoDeleteLink ?? false) 'recurring_item_id': 'i3',
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

/// Tx detail, the "ผูกกับ" section (owner 2026-10-17): view mode shows all
/// three rows, an empty one as a dashed "+" chip; a tap only hints, a
/// long-press enters edit mode; edit mode keeps them dashed (no 🔒).
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
          syncCoordinatorProvider(),
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

  AppChip chip(WidgetTester t, String label) =>
      t.widget<AppChip>(find.widgetWithText(AppChip, label));

  testWidgets('view: the three link rows are dashed "+" chips', (t) async {
    await pump(t);
    expect(find.text('Save'), findsNothing);
    for (final label in ['Add person', 'Add event', 'Pick a recurring']) {
      expect(find.text(label), findsOneWidget, reason: label);
      expect(chip(t, label).dashed, isTrue, reason: label);
    }
  });

  testWidgets('view: a tap only hints; nothing is edited', (t) async {
    await pump(t);
    await t.tap(find.text('Add event'));
    await settle(t);
    // The hint is a snackbar (the note field's own placeholder says the
    // same, so look for the snackbar, not the words).
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Long-press to edit'),
      ),
      findsOneWidget,
    );
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('view: a long-press on a row enters edit mode', (t) async {
    await pump(t);
    await t.longPress(find.text('Split with people'));
    await settle(t);
    expect(find.text('Save'), findsOneWidget);
    // Edit mode: the add button is live (outlined), and no lock anywhere.
    expect(find.widgetWithText(AppButton, 'Add person'), findsOneWidget);
    expect(find.byIcon(AppIcons.lock), findsNothing);
  });
}
