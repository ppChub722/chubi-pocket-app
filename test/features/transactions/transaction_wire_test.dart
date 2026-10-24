import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/delete_results.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

/// Records the request; answers with [body].
class _Adapter implements HttpClientAdapter {
  Object? body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Accounts extends Fake implements AccountsCubit {
  final patched = <Map<String, double>>[];

  @override
  void patchBalances(Map<String, double> balances) => patched.add(balances);
}

class _Txs extends Fake implements TransactionsCubit {
  final dropped = <String>[];

  @override
  void dropRow(String id) => dropped.add(id);
}

class _Debts extends Fake implements DebtDirectoryCubit {
  final applied = <PersonBalance>[];

  @override
  void applyBalance(PersonBalance b) => applied.add(b);
}

const _lee = PersonBalance(
  key: 'c:c2',
  person: EmbeddedPerson(name: 'Lee', contactId: 'c2'),
  net: 40,
);

void main() {
  late _Adapter adapter;
  late TransactionsRepository repo;

  setUp(() {
    adapter = _Adapter();
    repo = TransactionsRepository(
      client: _FakeApi(Dio()..httpClientAdapter = adapter),
    );
  });

  test('DELETE /transactions/{id}: skip_occurrence / also_delete_link', () async {
    adapter.body = {'id': 't1'};
    for (final c in <({String name, bool? skip, bool? also, Map<String, dynamic> query})>[
      (name: 'skip', skip: true, also: null, query: {'skip_occurrence': true}),
      (
        name: 'tx only',
        skip: false,
        also: null,
        query: {'skip_occurrence': false},
      ),
      (name: 'no ask', skip: null, also: null, query: {}),
      (name: 'both sides', skip: null, also: true, query: {'also_delete_link': true}),
      (
        name: 'this side',
        skip: null,
        also: false,
        query: {'also_delete_link': false},
      ),
    ]) {
      await repo.delete('t1', skipOccurrence: c.skip, alsoDeleteLink: c.also);
      final sent = adapter.last!;
      expect(sent.method, 'DELETE', reason: c.name);
      expect(sent.path, '/transactions/t1', reason: c.name);
      expect(sent.queryParameters, c.query, reason: c.name);
    }
  });

  test('PUT /transactions/{id}: also_update_link and link_mode ride the body', () async {
    adapter.body = {
      'rows': [
        {'id': 't1', 'type': 'expense', 'amount': 10, 'date': '2026-10-21'},
      ],
    };
    for (final c in <({String name, bool? also, Map<String, dynamic>? link, Map<String, dynamic> body})>[
      (
        name: 'text-only edit: nothing about the link',
        also: null,
        link: null,
        body: {'description': 'x'},
      ),
      (
        name: 'both sides',
        also: true,
        link: null,
        body: {'description': 'x', 'also_update_link': true},
      ),
      (
        name: 'this side',
        also: false,
        link: null,
        body: {'description': 'x', 'also_update_link': false},
      ),
      (
        name: 'a tab switch carries link_mode',
        also: null,
        link: {'link_mode': 'personal'},
        body: {'description': 'x', 'link_mode': 'personal'},
      ),
    ]) {
      await repo.update(
        id: 't1',
        description: 'x',
        alsoUpdateLink: c.also,
        link: c.link,
      );
      final sent = adapter.last!;
      expect(sent.method, 'PUT', reason: c.name);
      expect(sent.path, '/transactions/t1', reason: c.name);
      expect(sent.queryParameters, isEmpty, reason: c.name);
      expect(sent.data, c.body, reason: c.name);
    }
  });

  test('PUT ?preview=true: the tab switch is previewed, not saved', () async {
    adapter.body = {'people': <dynamic>[], 'wallets': <dynamic>[]};
    await repo.previewUpdate(
      id: 't1',
      link: const {'link_mode': 'personal'},
    );
    final sent = adapter.last!;
    expect(sent.method, 'PUT');
    expect(sent.queryParameters, {'preview': 'true'});
    expect(sent.data, {'link_mode': 'personal'});
  });

  test('a tx delete patches the wallets; a repayment also the person', () {
    final accounts = _Accounts();
    final debts = _Debts();

    applyTxDeleteResult(
      const DeleteTransactionResult(id: 't1', accountBalances: {'w1': 90}),
      accounts: accounts,
      debts: debts,
    );
    expect(accounts.patched, [
      {'w1': 90.0},
    ]);
    expect(debts.applied, isEmpty);

    applyTxDeleteResult(
      const DeleteTransactionResult(
        id: 't2',
        accountBalances: {'w1': 50},
        personBalance: _lee,
      ),
      accounts: accounts,
      debts: debts,
    );
    expect(accounts.patched.last, {'w1': 50.0});
    expect(debts.applied, [_lee]);

    applyTxDeleteResult(
      const DeleteTransactionResult(
        id: 't3',
        accountBalances: {'w1': 10},
        personBalance: _lee,
      ),
      accounts: accounts,
    );
    expect(accounts.patched.last, {'w1': 10.0});
    expect(debts.applied, hasLength(1));
  });

  test('a debt entry delete patches the wallets and drops its tx row', () {
    final accounts = _Accounts();
    final txs = _Txs();

    applyDebtEntryDeleteResult(
      const DebtEntryDeleteResult(
        id: 'e1',
        balance: _lee,
        transactionId: 't9',
        accountBalances: {'w1': 800},
      ),
      accounts: accounts,
      txs: txs,
    );
    expect(accounts.patched, [
      {'w1': 800.0},
    ]);
    expect(txs.dropped, ['t9']);

    applyDebtEntryDeleteResult(
      const DebtEntryDeleteResult(id: 'e2', balance: _lee),
      accounts: accounts,
      txs: txs,
    );
    expect(accounts.patched.last, isEmpty);
    expect(txs.dropped, ['t9']);
  });
}
