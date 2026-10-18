import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/pages/transactions_list_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

/// A list answer as the BE sends it (0.4.0): `totals`, top-level
/// `avg_daily_spend` and `daily`.
Map<String, dynamic> _answer() => {
  'totals': {'income': 30540, 'expense': 18200, 'net': 12340, 'count': 2},
  'avg_daily_spend': 1138,
  'daily': [
    for (var d = 1; d <= 30; d++)
      {
        'date': '2026-10-${d.toString().padLeft(2, '0')}',
        'income': 0,
        'expense': d.isEven ? 600 : 200,
      },
  ],
};

class _Repo extends Fake implements TransactionsRepository {
  final queries = <({Set<TransactionType> types, String? from, String? to})>[];
  bool fail = false;

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
  }) async {
    queries.add((types: types, from: from, to: to));
    if (fail) {
      throw const ApiException(code: 'X', message: 'boom', statusCode: 500);
    }
    return TransactionsPage(
      transactions: [
        Transaction.fromJson({
          'id': 't1',
          'type': 'expense',
          'amount': 120,
          'date': '2026-10-16',
          'description': 'ข้าวกลางวัน',
        }),
      ],
      page: 1,
      perPage: 20,
      total: 1,
      totalPages: 1,
      totals: ListTotals.fromResponse(_answer()),
    );
  }
}

void main() {
  setUp(ToolbarToggleState.resetAll);

  late _Repo repo;

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(400, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final cubit = TransactionsCubit(repository: repo);
    addTearDown(cubit.close);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    await t.pumpWidget(
      RepositoryProvider<TransactionsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<TransactionsCubit>.value(value: cubit),
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
            home: const TransactionsListPage(),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
  }

  test('ListTotals.fromResponse reads the BE daily bars + average', () {
    final totals = ListTotals.fromResponse(_answer())!;
    expect(totals.net, 12340);
    expect(totals.avgDailySpend, 1138);
    expect(totals.daily, hasLength(30));
    expect(totals.daily.first.date, '2026-10-01');
    expect(totals.daily[1].expense, 600);
  });

  testWidgets('card: net, daily bars, avg line, tiles; search hidden', (
    t,
  ) async {
    repo = _Repo();
    await pump(t);
    expect(find.byType(AppHeroCard), findsOneWidget);
    expect(find.byType(DailyBars), findsOneWidget);
    expect(find.textContaining('Avg spend'), findsOneWidget);
    expect(find.byType(SummaryTileView), findsNWidgets(2));
    expect(find.textContaining('30,540'), findsOneWidget);
    expect(find.textContaining('18,200'), findsOneWidget);
    // The search row is behind the card's 🔍.
    expect(find.byType(TextField), findsNothing);
    await t.tap(find.byType(ToolbarToggleButton));
    await t.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('tiles are type filters; the second tap clears', (t) async {
    repo = _Repo();
    await pump(t);
    final before = repo.queries.length;
    await t.tap(find.byKey(const ValueKey('summaryTile:Expense')));
    await t.pump(const Duration(milliseconds: 200));
    expect(repo.queries.length, before + 1);
    expect(repo.queries.last.types, {TransactionType.expense});
    await t.tap(find.byKey(const ValueKey('summaryTile:Expense')));
    await t.pump(const Duration(milliseconds: 200));
    expect(repo.queries.last.types, isEmpty);
  });

  testWidgets('a bar opens that day', (t) async {
    repo = _Repo();
    await pump(t);
    final bars = find.descendant(
      of: find.byType(DailyBars),
      matching: find.byType(GestureDetector),
    );
    await t.tap(bars.at(3));
    await t.pump(const Duration(milliseconds: 200));
    expect(repo.queries.last.from, '2026-10-04');
    expect(repo.queries.last.to, '2026-10-04');
  });

  testWidgets('a failed first load → the page error, no card', (t) async {
    repo = _Repo()..fail = true;
    await pump(t);
    expect(find.byType(AppHeroCard), findsNothing);
    expect(find.text('Retry'), findsWidgets);
  });
}
