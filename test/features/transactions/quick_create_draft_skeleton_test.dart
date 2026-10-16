import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/form_options.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/quick_create_sheet.dart';
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

/// `GET /transactions/form-options` answers when the test says so.
class _Repo extends Fake implements TransactionsRepository {
  final options = Completer<TxFormOptions>();

  @override
  Future<TxFormOptions> formOptions() => options.future;
}

/// A pending draft as the BE sends it.
Map<String, dynamic> _draft() => {
  'id': 'p1',
  'source': 'manual',
  'kind': 'create',
  'draft': {
    'type': 'expense',
    'amount': 120,
    'description': 'Lunch',
    'account_id': 'a1',
  },
  'resolved': {
    'account': {
      'id': 'a1',
      'name': 'KBank',
      'icon_code': null,
      'logo_url': null,
      'type': 'bank',
      'group': 'asset',
      'currency': 'THB',
      'archived': false,
    },
    'transfer_to_account': null,
    'category': null,
    'tags': <Object>[],
    'project': null,
    'splits': <Object>[],
    'missing': ['category_id'],
  },
  'target_debt_id': null,
  'target_transaction_id': null,
  'source_ref': null,
  'last_error': null,
  'created_at': '2026-10-12T09:30:00Z',
  'updated_at': '2026-10-12T09:30:00Z',
};

/// แก้ร่าง opens at once (owner 2026-10-13: skeletons on the first load):
/// the EntryCard skeleton shows while the form options load, then the draft
/// prefills the real card.
void main() {
  testWidgets('draft: EntryCard skeleton until the form options land', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Repo();
    final accounts = _Accounts();
    final categories = _Categories();
    final tags = _Tags();
    final txs = _Txs();
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => tags.state).thenReturn(const TagsState());
    when(() => txs.state).thenReturn(const TransactionsState());
    when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => tags.loadIfNeeded()).thenAnswer((_) async {});

    await t.pumpWidget(
      RepositoryProvider<TransactionsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<TagsCubit>.value(value: tags),
            BlocProvider<TransactionsCubit>.value(value: txs),
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
                    draft: PendingTransaction.fromJson(_draft()),
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
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    // Open, but the options aren't here: the skeleton, no form yet.
    expect(find.byType(QuickCreateSheetShell), findsOneWidget);
    expect(find.byType(EntryCardSkeleton), findsOneWidget);
    expect(find.byType(EntryCard), findsNothing);

    repo.options.complete(const TxFormOptions());
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(EntryCardSkeleton), findsNothing);
    expect(find.byType(EntryCard), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
  });
}
