import 'package:chubi_pocket/core/data/data_changes.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(
  String id,
  String date, {
  TransactionType type = TransactionType.expense,
  double amount = 100,
  String? accountId = 'a1',
  String? categoryId = 'c1',
}) => Transaction.fromJson({
  'id': id,
  'account': accountId == null ? null : {'id': accountId, 'name': accountId},
  'type': type.toJson(),
  'amount': amount,
  'date': date,
  'category': categoryId == null
      ? null
      : {'id': categoryId, 'name': categoryId},
});

/// Serves [book] filtered like the BE would (the parts the tests use),
/// and records each list call's filters.
class _Repo extends Fake implements TransactionsRepository {
  _Repo(this.book);
  List<Transaction> book;
  final calls = <({TransactionType? type, String? from, String? to})>[];
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
    calls.add((type: type, from: from, to: to));
    final rows =
        book
            .where((t) => type == null || t.type == type)
            .where((t) => from == null || t.date.compareTo(from) >= 0)
            .where((t) => to == null || t.date.compareTo(to) <= 0)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return TransactionsPage(
      transactions: rows,
      page: 1,
      perPage: perPage,
      total: rows.length,
      totalPages: 1,
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
  }) async => next!;
}

/// A fresh book of three rows and a cubit over it.
class _Env {
  _Env()
    : repo = _Repo([
        _tx('t3', '2026-10-09'),
        _tx('t2', '2026-10-05', type: TransactionType.income),
        _tx('t1', '2026-10-02'),
      ]) {
    cubit = _open();
  }

  final _Repo repo;
  late final TransactionsCubit cubit;
  final _opened = <TransactionsCubit>[];

  TransactionsCubit _open() {
    final c = TransactionsCubit(repository: repo);
    _opened.add(c);
    return c;
  }

  TransactionsCubit another() => _open();

  List<String> ids() => cubit.state.transactions.map((t) => t.id).toList();

  Future<void> add(Transaction t) {
    repo.next = TransactionMutationResult.single(t);
    return cubit.add(type: t.type, amount: t.amount, date: t.date);
  }

  Future<void> close() async {
    for (final c in _opened) {
      await c.close();
    }
  }
}

typedef _Case = ({
  String name,
  Future<Object?> Function(_Env e) run,
  Object? expected,
});

Future<void> _check(List<_Case> cases) async {
  for (final c in cases) {
    final e = _Env();
    try {
      expect(await c.run(e), c.expected, reason: c.name);
    } finally {
      await e.close();
    }
  }
}

void main() {
  test('refresh table', () async {
    await _check([
      (
        name: 'refresh keeps the filters (no reset to all-time)',
        run: (e) async {
          await e.cubit.load(
            type: TransactionType.expense,
            from: '2026-10-01',
            to: '2026-10-31',
          );
          await e.cubit.refresh();
          return [
            e.repo.calls.last.type,
            e.repo.calls.last.from,
            e.repo.calls.last.to,
            e.ids(),
          ];
        },
        expected: [
          TransactionType.expense,
          '2026-10-01',
          '2026-10-31',
          ['t3', 't1'],
        ],
      ),
      (
        name: 'refresh before any load does nothing',
        run: (e) async {
          await e.cubit.refresh();
          return e.repo.calls;
        },
        expected: isEmpty,
      ),
    ]);
  });

  test('placement table', () async {
    await _check([
      (
        name: 'a new row that fails the filters stays out',
        run: (e) async {
          await e.cubit.load(type: TransactionType.income);
          await e.add(_tx('n1', '2026-10-10')); // an expense
          return e.ids();
        },
        expected: ['t2'],
      ),
      (
        name: 'a back-dated row lands at its date, not at the top',
        run: (e) async {
          await e.cubit.load(from: '2026-10-01', to: '2026-10-31');
          await e.add(_tx('n1', '2026-10-04'));
          return e.ids();
        },
        expected: ['t3', 't2', 'n1', 't1'],
      ),
      (
        name: 'a new row is first among its own day (newest first)',
        run: (e) async {
          await e.cubit.load();
          await e.add(_tx('n1', '2026-10-05'));
          return e.ids();
        },
        expected: ['t3', 'n1', 't2', 't1'],
      ),
      (
        name: 'outside the date range → not shown',
        run: (e) async {
          await e.cubit.load(from: '2026-10-01', to: '2026-10-31');
          await e.add(_tx('n1', '2026-09-30'));
          return e.ids();
        },
        expected: ['t3', 't2', 't1'],
      ),
      (
        name: 'oldest-first sort puts it at its place from the other end',
        run: (e) async {
          await e.cubit.load(sort: 'date_asc');
          // The fake always answers newest-first; set the expected order.
          e.cubit.emit(
            e.cubit.state.copyWith(
              transactions: [
                _tx('t1', '2026-10-02'),
                _tx('t2', '2026-10-05', type: TransactionType.income),
                _tx('t3', '2026-10-09'),
              ],
            ),
          );
          await e.add(_tx('n1', '2026-10-05'));
          return e.ids();
        },
        expected: ['t1', 't2', 'n1', 't3'],
      ),
      (
        name: 'an edit that changes the date moves the row',
        run: (e) async {
          await e.cubit.load();
          e.repo.next = TransactionMutationResult.single(
            _tx('t1', '2026-10-10'),
          );
          await e.cubit.updateTransaction(id: 't1', date: '2026-10-10');
          return e.ids();
        },
        expected: ['t1', 't3', 't2'],
      ),
      (
        name: 'an edit that leaves the filter drops the row',
        run: (e) async {
          await e.cubit.load(type: TransactionType.expense);
          e.repo.next = TransactionMutationResult.single(
            _tx('t1', '2026-10-02', type: TransactionType.income),
          );
          await e.cubit.updateTransaction(id: 't1');
          return e.ids();
        },
        expected: ['t3'],
      ),
    ]);
  });

  test('live-lists table', () async {
    await _check([
      (
        name: 'a write in one list refreshes the other live lists',
        run: (e) async {
          final walletTab = e.another();
          await e.cubit.load();
          await walletTab.load(type: TransactionType.expense);
          e.repo.calls.clear();
          final created = _tx('n1', '2026-10-10');
          e.repo.book = [created, ...e.repo.book];
          await e.add(created);
          await Future<void>.delayed(Duration.zero);
          // The wallet tab re-fetched with its own filter.
          return [
            e.repo.calls.single.type,
            walletTab.state.transactions.first.id,
          ];
        },
        expected: [TransactionType.expense, 'n1'],
      ),
      (
        name:
            'a transactions change refreshes every live list, each with its '
            'filters',
        run: (e) async {
          final other = e.another();
          await e.cubit.load(type: TransactionType.income);
          await other.load(type: TransactionType.expense);
          e.repo.calls.clear();
          await DataChanges.instance.changed({DataTable.transactions});
          return e.repo.calls.map((c) => c.type).toList();
        },
        expected: containsAll([
          TransactionType.income,
          TransactionType.expense,
        ]),
      ),
    ]);
  });
}
