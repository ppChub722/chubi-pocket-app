import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A row as the list serves it: `split_count` only. With [withSplits], as
/// GET /:id serves it: the people too.
Transaction _tx(String id, {int splitCount = 0, bool withSplits = false}) =>
    Transaction.fromJson({
      'id': id,
      'account_id': 'a1',
      'type': 'expense',
      'amount': 300,
      'date': '2026-10-10',
      'category_id': 'c1',
      'split_count': splitCount,
      if (withSplits)
        'splits': [
          for (var i = 0; i < splitCount; i++)
            {
              'debt_id': 'd$i',
              'person_name': 'P$i',
              'amount': 100,
              'status': 'open',
            },
        ],
    });

/// The list carries totals (as it has since 0.3.1-4), so any write path
/// re-fetches page 1 — rows without splits.
class _Repo extends Fake implements TransactionsRepository {
  _Repo(this.rows);
  List<Transaction> rows;
  Transaction? one;
  int lists = 0;

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
    lists++;
    return TransactionsPage(
      transactions: rows,
      page: 1,
      perPage: perPage,
      total: rows.length,
      totalPages: 1,
      totals: const ListTotals(income: 0, expense: 300, net: -300),
    );
  }

  @override
  Future<Transaction> get(String id) async => one!;
}

void main() {
  late _Repo repo;
  late TransactionsCubit cubit;

  setUp(() async {
    repo = _Repo([_tx('t1', splitCount: 2)]);
    cubit = TransactionsCubit(repository: repo);
    await cubit.load();
  });

  tearDown(() => cubit.close());

  Transaction row() => cubit.byId('t1')!;

  test('refreshOne is a read: no page-1 refetch, splits stay', () async {
    expect(cubit.state.totals, isNotNull);
    repo.one = _tx('t1', splitCount: 2, withSplits: true);
    final before = repo.lists;
    final revision = cubit.state.revision;

    await cubit.refreshOne('t1');
    await Future<void>.delayed(Duration.zero);

    expect(repo.lists, before);
    expect(cubit.state.revision, revision);
    expect(row().splits, hasLength(2));
  });

  test('a later refresh keeps the fetched splits (same split_count)', () async {
    repo.one = _tx('t1', splitCount: 2, withSplits: true);
    await cubit.refreshOne('t1');

    await cubit.refresh();

    expect(row().splits, hasLength(2));
  });

  test('refreshOne after a write re-fetches, splits survive it', () async {
    repo.one = _tx('t1', splitCount: 2, withSplits: true);
    final before = repo.lists;

    await cubit.refreshOne('t1', afterWrite: true);
    await Future<void>.delayed(Duration.zero);

    expect(repo.lists, greaterThan(before));
    expect(row().splits, hasLength(2));
  });

  test('a changed split_count drops the cached splits', () async {
    repo.one = _tx('t1', splitCount: 2, withSplits: true);
    await cubit.refreshOne('t1');
    repo.rows = [_tx('t1', splitCount: 3)];

    await cubit.refresh();

    expect(row().splits, isEmpty);
    expect(row().splitCount, 3);
  });
}
