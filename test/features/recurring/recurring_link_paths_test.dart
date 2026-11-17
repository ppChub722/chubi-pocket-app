import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_link_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recurring_fixtures.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({'transaction': null, 'item': null}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 0.4.3: a round lives under its item AND its line; an item with 2+ lines
/// has line ids that differ from the item id.
void main() {
  test('a list row\'s current round carries its own line', () {
    final r = Recurring.fromJson({
      ...prodRecurringJson(),
      'id': 'item1',
      'current_occurrence': {
        'item_id': null,
        'recurring_rule_id': 'line2',
        'slot': '2026-11-20',
        'date': '2026-11-20',
        'days_until': 2,
        'amount': 500,
        'status': 'upcoming',
      },
    });
    expect(r.currentOccurrence!.ruleId, 'line2');
    expect(r.currentOccurrence!.itemId, 'slot:line2:2026-11-20');
  });

  test('a tx\'s recurring link keeps the item and the line apart', () {
    final link = RecurringItemLink.fromJson({
      'item_id': 'row9',
      'recurring': {
        'id': 'item7',
        'recurring_rule_id': 'line8',
        'name': 'ค่าเช่า',
      },
      'slot': '2026-11-01',
    });
    expect(link.recurringId, 'item7');
    expect(link.recurringRuleId, 'line8');
  });

  test('link / unlink a round go to /recurring/{item}/lines/{line}', () async {
    final http = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = http;
    final repo = RecurringLinkRepository(client: _FakeApi(dio));

    // Learned from a list row (item1 → line2) and a tx link (item7 → line8).
    Recurring.fromJson({
      ...prodRecurringJson(),
      'id': 'item1',
      'current_occurrence': {
        'recurring_rule_id': 'line2',
        'slot': '2026-11-20',
        'date': '2026-11-20',
        'status': 'upcoming',
      },
    });
    RecurringItemLink.fromJson({
      'recurring': {'id': 'item7', 'recurring_rule_id': 'line8'},
      'slot': '2026-11-01',
    });

    await repo.linkOccurrence('line2', '2026-11-20', 'tx1');
    expect(
      http.last!.path,
      '/recurring/item1/lines/line2/occurrences/2026-11-20/link',
    );
    expect(http.last!.data, {'transaction_id': 'tx1'});

    await repo.unlinkOccurrence('line8', '2026-11-01');
    expect(
      http.last!.path,
      '/recurring/item7/lines/line8/occurrences/2026-11-01/unlink',
    );

    // A line never seen is its own item (a migrated one keeps its rule's id).
    await repo.unlinkOccurrence('r1', '2026-11-03');
    expect(
      http.last!.path,
      '/recurring/r1/lines/r1/occurrences/2026-11-03/unlink',
    );
  });
}
