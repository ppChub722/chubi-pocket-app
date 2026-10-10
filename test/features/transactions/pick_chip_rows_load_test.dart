import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/pick_chip_rows.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/skeleton_box.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

/// QA run-3 E2: the pick rows fetch their own list when nothing has yet
/// (the filter sheet opened before any page loaded it), shimmering until
/// it comes.
void main() {
  late _Accounts accounts;
  late _Categories categories;
  late _Tags tags;

  setUp(() {
    accounts = _Accounts();
    categories = _Categories();
    tags = _Tags();
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => tags.state).thenReturn(const TagsState());
    when(() => accounts.loadIfNeeded()).thenAnswer((_) async {});
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => tags.loadIfNeeded()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester t, Widget row) {
    final txs = _Txs();
    when(() => txs.state).thenReturn(const TransactionsState());
    return t.pumpWidget(
      MultiBlocProvider(
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
          locale: const Locale('th'),
          home: Scaffold(body: row),
        ),
      ),
    );
  }

  testWidgets('wallet row: loads the wallets, shimmers meanwhile', (t) async {
    await pump(
      t,
      WalletChipRow(
        selectedId: null,
        onPick: (_) {},
        onMore: () {},
        order: ChipOrder(),
      ),
    );
    expect(find.byType(SkeletonBox), findsWidgets);
    await t.pump();
    verify(() => accounts.loadIfNeeded()).called(1);
  });

  testWidgets('category row: loads the categories', (t) async {
    await pump(
      t,
      CategoryChipRow(
        type: null,
        selected: null,
        onPick: (_) {},
        onMore: () {},
        order: ChipOrder(),
      ),
    );
    expect(find.byType(SkeletonBox), findsWidgets);
    await t.pump();
    verify(() => categories.loadIfNeeded()).called(1);
  });

  testWidgets('tag row: loads the tags', (t) async {
    await pump(
      t,
      TagChipRow(
        selected: const {},
        onToggle: (_) {},
        onMore: () {},
        order: ChipOrder(),
      ),
    );
    await t.pump();
    verify(() => tags.loadIfNeeded()).called(1);
  });

  testWidgets('loaded but empty: no shimmer', (t) async {
    when(
      () => accounts.state,
    ).thenReturn(const AccountsState(status: AccountsStatus.loaded));
    await pump(
      t,
      WalletChipRow(
        selectedId: null,
        onPick: (_) {},
        onMore: () {},
        order: ChipOrder(),
      ),
    );
    expect(find.byType(SkeletonBox), findsNothing);
  });
}
