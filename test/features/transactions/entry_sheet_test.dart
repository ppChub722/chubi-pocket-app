import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/form_options.dart';
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

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Repo extends Fake implements TransactionsRepository {
  final options = Completer<TxFormOptions>();

  @override
  Future<TxFormOptions> formOptions() => options.future;
}

/// The edit-one-item sheet (owner 2026-10-13: an upcoming / produced
/// recurring item, a draft): the quick-form look prefilled from a body, the
/// skeleton until the pickers' options land, and the CALLER'S actions save.
void main() {
  late _Repo repo;
  late List<String> calls;
  late List<PendingDraft> bodies;
  late bool succeed;
  Future<bool>? result;

  Future<void> open(WidgetTester t, {bool withDelete = false}) async {
    SharedPreferences.setMockInitialValues({});
    repo = _Repo();
    calls = [];
    bodies = [];
    succeed = true;
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
    EntrySheetAction action(String label, {bool primary = true}) =>
        EntrySheetAction(
          label: label,
          primary: primary,
          onPressed: (d) async {
            calls.add(label);
            bodies.add(d);
            return succeed;
          },
        );
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
                  onPressed: () => result = showEntrySheet(
                    context,
                    title: 'Edit upcoming item',
                    initial: const PendingDraft(
                      type: TransactionType.expense,
                      amount: 419,
                      description: 'Netflix',
                      date: '2026-11-03',
                    ),
                    actions: [
                      action('Send to drafts', primary: false),
                      action('Save now'),
                    ],
                    onDelete: withDelete
                        ? () async {
                            calls.add('delete');
                            return true;
                          }
                        : null,
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
  }

  Future<void> land(WidgetTester t) async {
    repo.options.complete(const TxFormOptions());
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('skeleton until the options land; then the item, no mode '
      'chips, the caller’s two buttons', (t) async {
    await open(t);
    expect(find.text('Edit upcoming item'), findsOneWidget);
    expect(find.byType(EntryCardSkeleton), findsOneWidget);
    await land(t);
    expect(find.byType(EntryCardSkeleton), findsNothing);
    expect(find.byType(EntryCard), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.byType(QuickCreateModeChips), findsNothing);
    expect(find.text('Send to drafts'), findsOneWidget);
    expect(find.text('Save now'), findsOneWidget);
  });

  testWidgets('the main action gets the edited body; true closes', (t) async {
    await open(t);
    await land(t);
    await t.tap(find.text('Save now'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(calls, ['Save now']);
    expect(bodies.single.amount, 419);
    expect(bodies.single.description, 'Netflix');
    expect(bodies.single.date, '2026-11-03');
    expect(find.byType(QuickCreateSheetShell), findsNothing);
    expect(await result, isTrue);
  });

  testWidgets('false keeps the sheet open (the caller said why)', (t) async {
    await open(t);
    await land(t);
    succeed = false;
    await t.tap(find.text('Send to drafts'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(calls, ['Send to drafts']);
    expect(find.byType(QuickCreateSheetShell), findsOneWidget);
  });

  testWidgets('onDelete adds the 🗑; done closes', (t) async {
    await open(t, withDelete: true);
    await land(t);
    await t.tap(find.byTooltip('Delete'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(calls, ['delete']);
    expect(find.byType(QuickCreateSheetShell), findsNothing);
  });
}
