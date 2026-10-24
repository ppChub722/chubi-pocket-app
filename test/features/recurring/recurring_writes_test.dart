import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/recurring/presentation/item_write_apply.dart';
import 'package:chubi_pocket/features/recurring/presentation/occurrence_actions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recurring_fixtures.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

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

Map<String, dynamic> _item(
  String? id,
  String slot, {
  num amount = 419,
  String status = 'upcoming',
}) => {
  'id': id,
  'rule_id': 'r1',
  'slot': slot,
  'date': slot,
  'type': 'expense',
  'status': status,
  'amount': amount,
  'recurring': {'id': 'r1', 'name': 'Netflix'},
};

void main() {
  late _Adapter http;
  late RecurringRepository repo;

  setUp(() {
    http = _Adapter();
    repo = RecurringRepository(
      client: _FakeApi(Dio()..httpClientAdapter = http),
    );
  });

  test('edit amount, skip and confirm all by rule are ONE request each', () async {
    http.body = {
      'item': _item('i1', '2026-11-03', amount: 500),
      'account_balances': [
        {'account_id': 'a1', 'balance': 1200.5},
      ],
      'left_out': [
        {'slot': '2026-12-03', 'reason': 'needs_amount'},
      ],
    };

    await repo.editOccurrence('i1', amount: 500);
    expect(http.last!.method, 'PUT');
    expect(http.last!.path, '/recurring-items/i1');
    expect(http.last!.data, {'amount': 500, 'scope': 'this'});
    await repo.editOccurrence('i1', date: DateTime(2026, 12, 5));
    expect(http.last!.data, {'date': '2026-12-05', 'scope': 'this'});

    await repo.skipOccurrence('r1', '2026-11-03');
    expect(http.last!.method, 'POST');
    expect(http.last!.path, '/recurring/r1/occurrences/2026-11-03/skip');
    expect(http.last!.data, <String, dynamic>{});
    await repo.skipOccurrence('r1', '2026-11-03', deleteTx: true);
    expect(http.last!.data, {'delete_tx': true});

    for (final c in [
      (action: OccurrenceBulk.confirm, path: 'confirm-ready'),
      (action: OccurrenceBulk.markPaid, path: 'mark-paid-ready'),
      (action: OccurrenceBulk.skip, path: 'skip-ready'),
    ]) {
      final r = await repo.settleAll('r1', c.action);
      expect(http.last!.method, 'POST', reason: c.path);
      expect(http.last!.path, '/recurring/r1/occurrences/${c.path}');
      expect(r.leftOut.single.reason, 'needs_amount', reason: c.path);
      expect(r.balances, {'a1': 1200.5}, reason: c.path);
    }

    await repo.updateOccurrence('r1', '2026-11-03', {'description': null});
    expect(http.last!.method, 'PUT');
    expect(http.last!.path, '/recurring/r1/occurrences/2026-11-03');
    expect(http.last!.data, {'description': null});
  });

  test('a no-end rule pages the upcoming list by year, others by page', () async {
    http.body = {
      'data': [_item('i1', '2027-10-17')],
      'pagination': {'page': 1, 'total_pages': 1},
      'window': {
        'from': '2026-10-17',
        'to': '2027-10-16',
        'next_from': '2027-10-17',
      },
    };
    final year = await repo.items('r1', upcoming: true);
    expect(http.last!.path, '/recurring/r1/items');
    expect(http.last!.queryParameters, {'tab': 'upcoming', 'page': 1});
    expect(year.windowed, isTrue);
    expect(year.nextFrom, DateTime(2027, 10, 17));

    http.body = {
      'data': [_item('i2', '2028-03-17')],
      'pagination': {'page': 1, 'total_pages': 1},
      'window': {
        'from': '2027-10-17',
        'to': '2028-10-16',
        'next_from': null,
      },
    };
    final next = await repo.items('r1', upcoming: true, from: year.nextFrom);
    expect(http.last!.queryParameters, {
      'tab': 'upcoming',
      'from': '2027-10-17',
      'months': 12,
    });
    final all = next.after(year);
    expect(all.items.map((i) => i.id), ['i1', 'i2']);
    expect(all.nextFrom, isNull);

    http.body = {
      'data': [_item('i3', '2026-09-03', status: 'done')],
      'pagination': {'page': 2, 'total_pages': 3},
    };
    final produced = await repo.items('r1', upcoming: false, page: 2);
    expect(http.last!.queryParameters, {'tab': 'produced', 'page': 2});
    expect(produced.windowed, isFalse);
    expect(produced.hasMore, isTrue);
  });

  test('an item write: the setting patches the card, none means re-read; '
      'rows move between past and upcoming', () {
    final produced = ItemPage(
      items: [RecurringItem.fromJson(prodItemJson())],
      totalPages: 2,
    );
    final upcoming = ItemPage(
      items: [
        RecurringItem.fromJson(
          prodItemJson(status: 'upcoming', date: '2026-11-03'),
        ),
        RecurringItem.fromJson(
          prodItemJson(status: 'upcoming', date: '2026-12-03'),
        ),
      ],
      windowed: true,
      nextFrom: DateTime(2027, 10, 17),
    );
    final detail = RecurringDetail(
      recurring: Recurring.fromJson(prodRecurringJson()),
      produced: produced,
      upcoming: upcoming,
    );
    final now = DateTime(2026, 10, 20);
    ids(ItemPage p) => p.items.map((i) => i.id).toList();

    for (final c in [
      (
        name: 'confirmed: leaves upcoming for the past, newest first; setting patches',
        status: 'done',
        setting: true,
        produced: ['i-2026-11-03', 'i-2026-10-03'],
        upcoming: ['i-2026-12-03'],
        saved: 7,
      ),
      (
        name: 'skipped ahead of today: stays in upcoming; no setting keeps the card',
        status: 'archived',
        setting: false,
        produced: ['i-2026-10-03'],
        upcoming: ['i-2026-11-03', 'i-2026-12-03'],
        saved: 1,
      ),
    ]) {
      final r = ItemWriteResult.fromJson({
        'item': prodItemJson(status: c.status, date: '2026-11-03'),
        if (c.setting) 'setting': {...prodRecurringJson(), 'saved_count': 7},
      });
      expect(r.setting != null, c.setting, reason: c.name);
      final a = applyItemWrite(
        r,
        produced: produced,
        upcoming: upcoming,
        detail: detail,
        now: now,
      );
      expect(ids(a.produced), c.produced, reason: c.name);
      expect(ids(a.upcoming), c.upcoming, reason: c.name);
      expect(a.produced.totalPages, 2, reason: c.name);
      expect(a.upcoming.windowed, isTrue, reason: c.name);
      expect(a.upcoming.nextFrom, DateTime(2027, 10, 17), reason: c.name);
      expect(a.detail!.recurring.savedCount, c.saved, reason: c.name);
    }
    final none = applyItemWrite(
      const ItemWriteResult(),
      produced: produced,
      upcoming: upcoming,
      detail: null,
      now: now,
    );
    expect(none.detail, isNull);
    expect(
      ItemWriteResult.fromJson({'setting': prodRecurringJson()}).setting?.name,
      'Netflix',
    );
  });

  test('write patches: only changed fields go, a result patches the row by '
      'id or slot', () {
    for (final c in [
      (
        name: 'amount only',
        was: const PendingDraft(amount: 419, date: '2026-11-03'),
        now: const PendingDraft(amount: 500, date: '2026-11-03'),
        want: <String, dynamic>{'amount': 500.0},
      ),
      (
        name: 'moved date',
        was: const PendingDraft(amount: 419, date: '2026-11-03'),
        now: const PendingDraft(amount: 419, date: '2026-12-05'),
        want: <String, dynamic>{'date': '2026-12-05'},
      ),
      (
        name: 'blank text equals none',
        was: const PendingDraft(),
        now: const PendingDraft(note: '  '),
        want: <String, dynamic>{},
      ),
      (
        name: 'a cleared text sends null',
        was: const PendingDraft(description: 'Plan'),
        now: const PendingDraft(description: ''),
        want: <String, dynamic>{'description': null},
      ),
      (
        name: 'tags compare as a set',
        was: const PendingDraft(tagIds: ['a', 'b']),
        now: const PendingDraft(tagIds: ['b', 'a']),
        want: <String, dynamic>{},
      ),
      (
        name: 'wallet, category, tags changed',
        was: const PendingDraft(
          accountId: 'a1',
          categoryId: 'c1',
          tagIds: ['a', 'b'],
        ),
        now: const PendingDraft(
          accountId: 'a2',
          categoryId: 'c2',
          tagIds: ['a'],
        ),
        want: <String, dynamic>{
          'account_id': 'a2',
          'category_id': 'c2',
          'tag_ids': ['a'],
        },
      ),
    ]) {
      expect(occurrenceFields(c.was, c.now), c.want, reason: c.name);
    }

    final list = [
      RecurringItem.fromJson(_item('i1', '2026-11-03')),
      RecurringItem.fromJson(_item(null, '2026-12-03')),
    ];
    final stored = ItemWriteResult.fromJson({
      'item': _item('i2', '2026-12-03', amount: 500),
    });
    final patched = stored.applyTo(list);
    expect(patched.map((i) => i.id), ['i1', 'i2']);
    expect(patched.last.amount, 500);
    final gone = ItemWriteResult.fromJson({'id': 'i1'});
    expect(gone.applyTo(list).map((i) => i.slot), ['2026-12-03']);
  });
}
