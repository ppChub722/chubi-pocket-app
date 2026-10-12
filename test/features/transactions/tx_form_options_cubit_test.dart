import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/form_options.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/tx_form_options_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo extends Fake implements TransactionsRepository {
  int calls = 0;
  ApiException? fail;

  @override
  Future<TxFormOptions> formOptions() async {
    calls++;
    final f = fail;
    if (f != null) throw f;
    return TxFormOptions.fromJson(_sample);
  }
}

const _sample = <String, dynamic>{
  'accounts': [
    {
      'id': 'a1',
      'name': 'Cash',
      'type': 'cash',
      'balance': 120.5,
      'is_default': false,
    },
    {
      'id': 'a2',
      'name': 'Bank',
      'type': 'bank',
      'balance': 5000,
      'is_default': true,
    },
  ],
  'default_account_id': 'a2',
  'categories': [
    {
      'id': 'c1',
      'name': 'Food',
      'type': 'expense',
      'depth': 1,
      'sort_order': 1,
    },
    {
      'id': 'c2',
      'name': 'Lunch',
      'type': 'expense',
      'parent_id': 'c1',
      'parent_name': 'Food',
      'depth': 2,
      'sort_order': 2,
    },
  ],
  'tags': [
    {'id': 't1', 'name': 'trip', 'usage_count': 3},
  ],
  'events': [
    {'id': 'e1', 'name': 'Chiang Mai', 'status': 'active'},
  ],
  'fee_category_id': 'c9',
};

void main() {
  test('TxFormOptions.fromJson parses the sample', () {
    final o = TxFormOptions.fromJson(_sample);
    expect(o.accountList.map((a) => a.id), ['a1', 'a2']);
    expect(o.accountList.first.balance, 120.5);
    expect(o.defaultAccount?.id, 'a2');
    expect(o.categoryList.map((c) => c.id), ['c1', 'c2']);
    expect(o.categoryList.last.parentId, 'c1');
    expect(o.categories.last.parentName, 'Food');
    expect(o.tags.single.name, 'trip');
    expect(o.events.single.name, 'Chiang Mai');
    expect(o.feeCategoryId, 'c9');
  });

  test('load goes initial -> loading -> loaded', () async {
    final repo = _Repo();
    final cubit = TxFormOptionsCubit(repo);
    expect(cubit.state.isLoading, isTrue);
    final f = cubit.load();
    expect(cubit.state.status, TxFormOptionsStatus.loading);
    await f;
    expect(cubit.state.status, TxFormOptionsStatus.loaded);
    expect(cubit.state.options?.defaultAccountId, 'a2');
    expect(cubit.state.isLoading, isFalse);
    await cubit.close();
  });

  test('loadIfNeeded calls the repository once', () async {
    final repo = _Repo();
    final cubit = TxFormOptionsCubit(repo);
    await Future.wait([cubit.loadIfNeeded(), cubit.loadIfNeeded()]);
    await cubit.loadIfNeeded();
    expect(repo.calls, 1);
    await cubit.close();
  });

  test('a failure lands in error and loadIfNeeded retries', () async {
    final repo = _Repo()
      ..fail = const ApiException(code: 'NETWORK', message: 'down');
    final cubit = TxFormOptionsCubit(repo);
    await cubit.loadIfNeeded();
    expect(cubit.state.status, TxFormOptionsStatus.error);
    expect(cubit.state.error?.code, 'NETWORK');
    expect(cubit.state.options, isNull);
    repo.fail = null;
    await cubit.loadIfNeeded();
    expect(cubit.state.status, TxFormOptionsStatus.loaded);
    expect(repo.calls, 2);
    await cubit.close();
  });
}
