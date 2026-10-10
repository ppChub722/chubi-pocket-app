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
  'account_id': accountId,
  'type': type.toJson(),
  'amount': amount,
  'date': date,
  'category_id': categoryId,
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
    List<Map<String, dynamic>>? splits,
    String? sourceProjectTransactionId,
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
  }) async => next!;
}

void main() {
  late _Repo repo;
  late TransactionsCubit cubit;

  setUp(() {
    repo = _Repo([
      _tx('t3', '2026-10-09'),
      _tx('t2', '2026-10-05', type: TransactionType.income),
      _tx('t1', '2026-10-02'),
    ]);
    cubit = TransactionsCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  List<String> ids() => cubit.state.transactions.map((t) => t.id).toList();

  Future<void> add(Transaction t) {
    repo.next = TransactionMutationResult.single(t);
    return cubit.add(type: t.type, amount: t.amount, date: t.date);
  }

  test('refresh keeps the filters (no reset to all-time)', () async {
    await cubit.load(
      type: TransactionType.expense,
      from: '2026-10-01',
      to: '2026-10-31',
    );
    await cubit.refresh();
    expect(repo.calls.last.type, TransactionType.expense);
    expect(repo.calls.last.from, '2026-10-01');
    expect(repo.calls.last.to, '2026-10-31');
    expect(ids(), ['t3', 't1']);
  });

  test('refresh before any load does nothing', () async {
    await cubit.refresh();
    expect(repo.calls, isEmpty);
  });

  test('a new row that fails the filters stays out', () async {
    await cubit.load(type: TransactionType.income);
    await add(_tx('n1', '2026-10-10')); // an expense
    expect(ids(), ['t2']);
  });

  test('a back-dated row lands at its date, not at the top', () async {
    await cubit.load(from: '2026-10-01', to: '2026-10-31');
    await add(_tx('n1', '2026-10-04'));
    expect(ids(), ['t3', 't2', 'n1', 't1']);
  });

  test('a new row is first among its own day (newest first)', () async {
    await cubit.load();
    await add(_tx('n1', '2026-10-05'));
    expect(ids(), ['t3', 'n1', 't2', 't1']);
  });

  test('outside the date range → not shown', () async {
    await cubit.load(from: '2026-10-01', to: '2026-10-31');
    await add(_tx('n1', '2026-09-30'));
    expect(ids(), ['t3', 't2', 't1']);
  });

  test('oldest-first sort puts it at its place from the other end', () async {
    await cubit.load(sort: 'date_asc');
    // The fake always answers newest-first; set the expected order.
    cubit.emit(
      cubit.state.copyWith(
        transactions: [
          _tx('t1', '2026-10-02'),
          _tx('t2', '2026-10-05', type: TransactionType.income),
          _tx('t3', '2026-10-09'),
        ],
      ),
    );
    await add(_tx('n1', '2026-10-05'));
    expect(ids(), ['t1', 't2', 'n1', 't3']);
  });

  test('an edit that changes the date moves the row', () async {
    await cubit.load();
    repo.next = TransactionMutationResult.single(_tx('t1', '2026-10-10'));
    await cubit.updateTransaction(id: 't1', date: '2026-10-10');
    expect(ids(), ['t1', 't3', 't2']);
  });

  test('an edit that leaves the filter drops the row', () async {
    await cubit.load(type: TransactionType.expense);
    repo.next = TransactionMutationResult.single(
      _tx('t1', '2026-10-02', type: TransactionType.income),
    );
    await cubit.updateTransaction(id: 't1');
    expect(ids(), ['t3']);
  });

  test('a write in one list refreshes the other live lists', () async {
    final walletTab = TransactionsCubit(repository: repo);
    addTearDown(walletTab.close);
    await cubit.load();
    await walletTab.load(type: TransactionType.expense);
    repo.calls.clear();
    final created = _tx('n1', '2026-10-10');
    repo.book = [created, ...repo.book];
    await add(created);
    await Future<void>.delayed(Duration.zero);
    // The wallet tab re-fetched with its own filter.
    expect(repo.calls.single.type, TransactionType.expense);
    expect(walletTab.state.transactions.first.id, 'n1');
  });

  test(
    'bookChanged refreshes every live list, each with its filters',
    () async {
      final other = TransactionsCubit(repository: repo);
      addTearDown(other.close);
      await cubit.load(type: TransactionType.income);
      await other.load(type: TransactionType.expense);
      repo.calls.clear();
      await TransactionsCubit.bookChanged();
      expect(
        repo.calls.map((c) => c.type),
        containsAll([TransactionType.income, TransactionType.expense]),
      );
    },
  );
}
