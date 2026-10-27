import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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

Map<String, dynamic> _entry({bool linked = false, String? at}) => {
  'id': 'e1',
  'key': 'c:c2',
  'kind': 'debt',
  'direction': 'paid',
  'amount': 300,
  'date': '2026-10-27',
  'paid': false,
  'partner_linked': linked,
  'disconnected_at': at,
};

void main() {
  test('D9: partner_linked / disconnected_at parse', () {
    final on = DebtEntry.fromJson(_entry(linked: true));
    expect(on.partnerLinked, isTrue);
    expect(on.disconnectedAt, isNull);
    final off = DebtEntry.fromJson(_entry(at: '2026-10-27T10:00:00Z'));
    expect(off.partnerLinked, isFalse);
    expect(off.disconnectedAt, isNotNull);
    expect(
      DebtEntry.fromJson(_entry()..remove('partner_linked')).partnerLinked,
      isFalse,
      reason: 'an older BE: not linked',
    );
  });

  test('D9: disconnect = ONE POST, no body', () async {
    final http = _Adapter()
      ..body = {
        'entry': _entry(at: '2026-10-27T10:00:00Z'),
        'person_balance': {
          'key': 'c:c2',
          'person': {'name': 'Lee'},
          'net': 300,
        },
        'transaction': null,
        'account_balances': const [],
      };
    final repo = PersonalDebtsRepository(
      client: _FakeApi(Dio()..httpClientAdapter = http),
    );
    final r = await repo.disconnect('e1');
    expect(http.last!.method, 'POST');
    expect(http.last!.path, '/personal-debts/e1/disconnect');
    expect(http.last!.data, isNull);
    expect(r.entry.partnerLinked, isFalse);
  });

  test('D9: the notice type reads from the wire', () {
    expect(
      NotificationType.fromWire('debt_disconnected'),
      NotificationType.debtDisconnected,
    );
  });
}
