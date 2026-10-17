import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

/// Records the request; answers with [body] / [status].
class _Adapter implements HttpClientAdapter {
  Object? body;
  int status = 200;
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
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _person = {
  'key': 'n:mom',
  'person': {
    'name': 'Mom',
    'contact_id': null,
    'icon_code': null,
    'linked': false,
    'linked_user_id': null,
  },
  'net': 200,
  'open_count': 1,
  'entry_count': 3,
  'last_activity_at': '2026-10-12',
};

const _entry = {
  'id': 'e1',
  'key': 'n:mom',
  'direction': 'paid',
  'amount': 200,
  'date': '2026-10-12',
  'description': 'Lunch money',
  'note': null,
  'paid': false,
  'source': {'kind': 'partner', 'id': null, 'title': 'Mom'},
  'transaction': {'id': 't1', 'account': null},
  'created_at': '2026-10-12T09:30:00Z',
  'updated_at': '2026-10-12T09:30:00Z',
};

const _write = {
  'entry': _entry,
  'person_balance': _person,
  'previous_person_balance': null,
  'transaction': null,
  'account_balances': [
    {'account_id': 'a1', 'balance': 800},
  ],
};

void main() {
  late _Adapter http;
  late PersonalDebtsRepository repo;

  setUp(() {
    http = _Adapter();
    repo = PersonalDebtsRepository(
      client: _FakeApi(Dio()..httpClientAdapter = http),
    );
  });

  Map<String, dynamic> sent() =>
      (http.last!.data as Map).cast<String, dynamic>();

  test('people: query params; totals + rows parsed', () async {
    http.body = {
      'data': [_person],
      'totals': {'owed_to_me': 200, 'i_owe': 0, 'net': 200, 'open_count': 1},
      'pagination': {'page': 1, 'per_page': 30, 'total': 1, 'total_pages': 1},
    };
    final p = await repo.listPeople(
      q: ' mo ',
      all: true,
      side: NetSide.iOwe,
      sort: DebtPeopleSort.amount,
    );
    expect(http.last!.path, '/personal-debts/people');
    expect(http.last!.queryParameters, {
      'page': '1',
      'per_page': '30',
      'q': 'mo',
      'all': 'true',
      'side': 'i_owe',
      'sort': 'amount',
    });
    // The default order is the BE's: longest outstanding first.
    await repo.listPeople();
    expect(http.last!.queryParameters['sort'], 'oldest');
    expect(p.items.single.key, 'n:mom');
    expect(p.items.single.entryCount, 3);
    expect(p.totals.openCount, 1);
    expect(p.paging.hasMore, isFalse);
  });

  test('person page: the key is URL-encoded; flat DebtPersonPage', () async {
    http.body = {
      ..._person,
      'cleared_at': '2026-10-05',
      'days_outstanding': 7,
      'counts': {'entries': 3, 'money': 1, 'current': 2, 'earlier': 1},
      'summary_message': {'text': 'สรุป', 'entries': 2, 'net': 200},
      'items': [_entry],
      'pagination': {'page': 1, 'per_page': 30, 'total': 3, 'total_pages': 1},
    };
    final d = await repo.person('n:mom & dad');
    expect(http.last!.uri.path, '/personal-debts/people/n%3Amom%20%26%20dad');
    // The current cycle, asked for explicitly.
    expect(http.last!.queryParameters['cycle'], 'current');
    expect(d.balance.net, 200);
    expect(d.balance.daysOutstanding, 7);
    expect(d.counts.earlier, 1);
    expect(d.message.text, 'สรุป');
    await repo.entries('n:mom', cycle: DebtCycle.earlier);
    expect(http.last!.queryParameters['cycle'], 'earlier');
    final e = d.entries.items.single;
    expect(e.source!.kind, 'partner');
    expect(e.source!.id, isNull);
    expect(e.transaction!.account, isNull);
  });

  test('createEntry: one POST; tags only with a wallet', () async {
    http.body = _write;
    http.status = 201;
    final r = await repo.createEntry(
      'n:mom',
      direction: DebtEntryDirection.received,
      amount: 50,
      date: DateTime(2026, 10, 3),
      tagIds: const ['t1'],
      personName: 'Mom',
    );
    expect(http.last!.method, 'POST');
    expect(http.last!.path, '/personal-debts/people/n%3Amom/entries');
    expect(sent(), {
      'direction': 'received',
      'amount': 50.0,
      'date': '2026-10-03',
      'person_name': 'Mom',
    });
    expect(r.balance.net, 200);
    expect(r.accountBalances, {'a1': 800.0});
    expect(r.transaction, isNull);
  });

  test('updateEntry: account_id null (ledger-only) ≠ absent', () async {
    http.body = _write;
    await repo.updateEntry('e1', const DebtEntryUpdate(clearAccount: true));
    expect(sent(), {'account_id': null});
    await repo.updateEntry('e1', const DebtEntryUpdate(note: ''));
    expect(sent(), {'note': ''});
    expect(sent().containsKey('account_id'), isFalse);
    await repo.setPaid('e1', true);
    expect(http.last!.method, 'PUT');
    expect(sent(), {'paid': true});
  });

  test('getEntry / deleteEntry / applySplit parse their results', () async {
    http.body = {
      'entry': _entry,
      'person_balance': _person,
      'transaction': null,
    };
    final d = await repo.getEntry('e1');
    expect(d.entry.description, 'Lunch money');
    expect(d.transaction, isNull);

    http.body = {
      'id': 'e1',
      'transaction_id': 't1',
      'person_balance': _person,
      'account_balances': <Object>[],
    };
    final del = await repo.deleteEntry('e1');
    expect(http.last!.method, 'DELETE');
    expect(del.transactionId, 't1');

    http.body = {'result': 'deleted', 'entry': null, 'person_balance': _person};
    final s = await repo.applySplit('n1');
    expect(http.last!.path, '/personal-debts/split-changes/n1/apply');
    expect(s.deleted, isTrue);
    expect(s.entry, isNull);
  });

  test('a 404 surfaces as ApiException', () async {
    http.body = {'code': 'NOT_FOUND', 'message': 'not found'};
    http.status = 404;
    await expectLater(repo.getEntry('gone'), throwsA(isA<ApiException>()));
  });
}
