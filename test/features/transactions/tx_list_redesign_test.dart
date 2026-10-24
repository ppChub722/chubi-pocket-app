import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/tags/domain/tag.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/tx_list_filters.dart';
import 'package:flutter_test/flutter_test.dart';

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
  ListTotals? totals = const ListTotals(income: 100, expense: 40, net: 60);
  int lists = 0;
  TransactionMutationResult? next;

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
    lists++;
    return TransactionsPage(
      transactions: const [],
      page: 1,
      perPage: perPage,
      total: 0,
      totalPages: 1,
      totals: totals,
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
  }) async => next!;
}

void main() {
  test('TxPeriod table', () {
    final cases =
        <({String name, Object? Function() actual, Object? expected})>[
          (
            name: 'month: bounds, steps, forward stops at this month',
            actual: () {
              final p = TxPeriod.month(DateTime(2026, 10, 15));
              return [
                p.bounds,
                p.step(-1),
                p.step(1)!.bounds.from,
                p.canStepForward(DateTime(2026, 10, 20)),
                p.step(-1)!.canStepForward(DateTime(2026, 10, 20)),
              ];
            },
            expected: [
              (from: '2026-10-01', to: '2026-10-31'),
              TxPeriod.month(DateTime(2026, 9)),
              '2026-11-01',
              false,
              true,
            ],
          ),
          (
            name:
                'day: one day, steps across month / year ends, stops at today',
            actual: () {
              final d = TxPeriod.day(DateTime(2026, 10, 10, 18, 30));
              return [
                d.bounds,
                d.step(-1)!.bounds.from,
                TxPeriod.day(DateTime(2026, 10, 31)).step(1),
                TxPeriod.day(DateTime(2026, 1, 1)).step(-1)!.bounds.from,
                d.canStepForward(DateTime(2026, 10, 10, 23)),
                d.step(-1)!.canStepForward(DateTime(2026, 10, 10)),
                TxPeriod.of(TxPeriodKind.day, DateTime(2026, 10, 10)) == d,
              ];
            },
            expected: [
              (from: '2026-10-10', to: '2026-10-10'),
              '2026-10-09',
              TxPeriod.day(DateTime(2026, 11, 1)),
              '2025-12-31',
              false,
              true,
              true,
            ],
          ),
          (
            name: 'a month step crosses the year',
            actual: () => TxPeriod.month(DateTime(2026, 1, 5)).step(-1)!.bounds,
            expected: (from: '2025-12-01', to: '2025-12-31'),
          ),
          (
            name: 'week: Monday to Sunday',
            actual: () {
              // 2026-10-10 is a Saturday.
              final w = TxPeriod.week(DateTime(2026, 10, 10));
              return [w.bounds, w.step(1)!.bounds.from];
            },
            expected: [(from: '2026-10-05', to: '2026-10-11'), '2026-10-12'],
          ),
          (
            name: 'year',
            actual: () {
              final y = TxPeriod.year(DateTime(2026, 6, 1));
              return [y.bounds, y.step(-1)];
            },
            expected: [
              (from: '2026-01-01', to: '2026-12-31'),
              TxPeriod.year(DateTime(2025)),
            ],
          ),
          (
            name: 'ทั้งหมด and a custom range have no neighbours',
            actual: () {
              final c = TxPeriod.custom(
                DateTime(2026, 10, 3),
                DateTime(2026, 10, 9),
              );
              return [
                TxPeriod.all.bounds,
                TxPeriod.all.step(1),
                c.bounds,
                c.step(-1),
              ];
            },
            expected: [
              (from: null, to: null),
              null,
              (from: '2026-10-03', to: '2026-10-09'),
              null,
            ],
          ),
          (
            name: 'switching unit keeps the place',
            actual: () {
              final week = TxPeriod.of(
                TxPeriodKind.week,
                DateTime(2026, 10, 1),
              );
              return [
                week.bounds.from,
                TxPeriod.of(TxPeriodKind.month, week.start),
              ];
            },
            expected: ['2026-09-28', TxPeriod.month(DateTime(2026, 9))],
          ),
        ];
    for (final c in cases) {
      expect(c.actual(), c.expected, reason: c.name);
    }
  });

  test('filters table', () {
    Account acc(String id) => Account.fromJson({
      'id': id,
      'name': id,
      'type': 'bank',
      'balance': 0,
      'currency': 'THB',
    });
    final cases =
        <({String name, Object? Function() actual, Object? expected})>[
          (
            name: 'sameFiltersAs ignores the period, sees tags in any order',
            actual: () {
              final a = TxFilters(
                period: TxPeriod.month(DateTime(2026, 10)),
                tags: const [
                  Tag(id: 't1', name: 'a'),
                  Tag(id: 't2', name: 'b'),
                ],
              );
              final b = a.copyWith(
                period: TxPeriod.all,
                tags: const [
                  Tag(id: 't2', name: 'b'),
                  Tag(id: 't1', name: 'a'),
                ],
              );
              return [
                a.sameFiltersAs(b),
                a.sameFiltersAs(
                  b.copyWith(types: const {TransactionType.expense}),
                ),
                a.sameFiltersAs(b.copyWith(tags: const [])),
              ];
            },
            expected: [true, false, false],
          ),
          (
            name: 'wallet filters compare by wallet id, and "no wallet" counts',
            actual: () {
              final p = TxPeriod.all;
              final a = TxFilters(period: p, wallets: [acc('a')]);
              final base = TxFilters(period: p);
              return [
                a.sameFiltersAs(TxFilters(period: p, wallets: [acc('a')])),
                a.sameFiltersAs(TxFilters(period: p, wallets: [acc('b')])),
                a.sameFiltersAs(
                  TxFilters(period: p, wallets: [acc('a')], noWallet: true),
                ),
                // "no wallet" next to a pick: two values on, one more than the
                // base.
                TxFilters(
                  period: p,
                  wallets: [acc('a')],
                  noWallet: true,
                ).activeCount(base),
              ];
            },
            expected: [true, false, false, 2],
          ),
        ];
    for (final c in cases) {
      expect(c.actual(), c.expected, reason: c.name);
    }
  });

  test('totals parse: the BE shape, absent → null, daily bars + average', () {
    final t = ListTotals.fromJson({
      'income': 12000.0,
      'expense': 8540,
      'net': 3460.0,
      'count': 57,
    })!;
    expect(t.income, 12000);
    expect(t.expense, 8540);
    expect(t.net, 3460);
    expect(t.count, 57);
    expect(ListTotals.fromJson(null), isNull);

    final totals = ListTotals.fromResponse(_answer())!;
    expect(totals.net, 12340);
    expect(totals.avgDailySpend, 1138);
    expect(totals.daily, hasLength(30));
    expect(totals.daily.first.date, '2026-10-01');
    expect(totals.daily[1].expense, 600);
  });

  test('totals re-fetch: the cubit keeps them, a write re-fetches', () async {
    final repo = _Repo();
    final cubit = TransactionsCubit(repository: repo);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.totals?.net, 60);
    final before = repo.lists;
    repo.next = TransactionMutationResult.single(
      Transaction.fromJson({
        'id': 'n',
        'type': 'expense',
        'amount': 10,
        'date': '2026-10-10',
      }),
    );
    await cubit.add(
      type: TransactionType.expense,
      amount: 10,
      date: '2026-10-10',
    );
    await Future<void>.delayed(Duration.zero);
    expect(repo.lists, greaterThan(before));

    final bare = _Repo()..totals = null;
    final bareCubit = TransactionsCubit(repository: bare);
    addTearDown(bareCubit.close);
    await bareCubit.load();
    expect(bareCubit.state.totals, isNull);
  });
}
