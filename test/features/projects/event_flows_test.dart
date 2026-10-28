import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/domain/claim.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/projects/presentation/widgets/project_common.dart';
import 'package:chubi_pocket/features/projects/presentation/widgets/project_tx_tiles.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'event_fixtures.dart';

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

/// 0.4.1-2 events app (App-2): the logic behind complete, delete, empty
/// spots, lump / claim / join, settle booking and multi-payer lines.
void main() {
  final l = lookupAppLocalizations(const Locale('th'));

  group('V3 status menu', () {
    test('active owner: every status incl. completed; without the right, '
        'completed is not offered', () {
      expect(
        eventStatusOptions(
          ProjectStatus.active,
          completed: false,
          canComplete: true,
        ),
        ProjectStatus.values,
      );
      expect(
        eventStatusOptions(
          ProjectStatus.active,
          completed: false,
          canComplete: false,
        ),
        isNot(contains(ProjectStatus.completed)),
      );
      expect(
        eventStatusOptions(
          ProjectStatus.cancelled,
          completed: false,
          canComplete: false,
        ),
        isNot(contains(ProjectStatus.completed)),
      );
    });

    test('completed (also once archived): only เสร็จสิ้น | เก็บถาวร, never '
        'back to active / cancelled', () {
      for (final current in [ProjectStatus.completed, ProjectStatus.archived]) {
        expect(
          eventStatusOptions(current, completed: true, canComplete: false),
          [ProjectStatus.completed, ProjectStatus.archived],
          reason: '$current',
        );
      }
    });
  });

  group('multi-payer board lines', () {
    ProjectView viewWith(Map<String, dynamic> row) => ProjectView.of(
      ProjectDetail.fromJson({
        ...detailJson(rows: [row]),
        'members': [
          for (final m in membersJson())
            m['name'] == 'Lee'
                ? {...m, 'status': 'left', 'removed_at': '2026-10-27T09:00:00Z'}
                : m,
        ],
      }),
      currentUserId: 'u-me',
    );
    String money(double v) => '฿${v.toStringAsFixed(0)}';

    test('2+ payers: each, biggest first, as the event knows them (a '
        'removed one = an empty spot)', () {
      final v = viewWith({
        ...boardRowJson(amount: 1200),
        'payers': [
          {'member': memberRef('m-lee', 'Lee'), 'amount': 700},
          {'member': memberRef('m-me', 'Pond', me: true), 'amount': 500},
        ],
      });
      final payers = projectBillPayers(l, v, v.txs.first, money);
      expect(payers.map((p) => (p.name, p.amount)), [
        (l.evbEmptyPerson, '฿700'),
        ('Pond', '฿500'),
      ]);
      expect(payers.first.level, PersonLevel.empty);
    });

    test('one payer: no list (the single-name line stays)', () {
      final v = viewWith({
        ...boardRowJson(),
        'payers': [
          {'member': memberRef('m-me', 'Pond', me: true), 'amount': 1000},
        ],
      });
      expect(projectBillPayers(l, v, v.txs.first, money), isEmpty);
    });
  });

  test('join (tx form / tx detail): only money bills someone else paid, '
      'not booked, with no copy of mine', () {
    ClaimableBill bill({
      String type = 'expense',
      bool payerIsMe = false,
      String? myTx,
      bool claimed = false,
    }) => ClaimableBill.tryParse({
      'pt_id': 'b',
      'type': type,
      'date': '2026-10-02',
      'bill_amount': 900,
      'payer': {'id': 'm-x', 'name': 'X', 'is_me': payerIsMe},
      'other': {'id': 'm-x', 'name': 'X'},
      'direction': 'received',
      'amount': 300,
      'my_transaction_id': myTx,
      'claimed': claimed,
    })!;
    expect(bill().joinable, isTrue);
    expect(bill(payerIsMe: true).joinable, isFalse);
    expect(bill(myTx: 'tx1').joinable, isFalse);
    expect(bill(claimed: true).joinable, isFalse);
    expect(bill(type: 'payback').joinable, isFalse);
  });

  test(
    'event write requests: one call each, the right path and body',
    () async {
      final http = _Adapter();
      final repo = ProjectsRepository(
        client: _FakeApi(Dio()..httpClientAdapter = http),
      );

      // V3 complete.
      http.body = patchJson();
      await repo.complete('e1');
      expect(
        (http.last!.method, http.last!.path),
        ('POST', '/projects/e1/complete'),
      );

      // Delete keeps the bills: no flag, the split-bill count back.
      http.body = {'id': 'e1', 'split_bill_count': 2, 'effects': {}};
      expect(await repo.delete('e1'), 2);
      expect(http.last!.queryParameters, isEmpty);

      // V15 empty spots: a BillPerson, bill_ids only when narrowed.
      http.body = patchJson();
      await repo.assignRemovedMember('e1', 'm-lee', to: {'me': true});
      expect(http.last!.path, '/projects/e1/members/m-lee/assign');
      expect(http.last!.data, {
        'to': {'me': true},
      });
      await repo.assignRemovedMember(
        'e1',
        'm-lee',
        to: {'person_name': 'Mai'},
        billIds: ['b1'],
      );
      expect((http.last!.data as Map)['bill_ids'], ['b1']);

      // Claim: the person by member / contact / name; the claim body.
      http.body = {'data': [], 'totals': []};
      await repo.claimable('e1', contactId: 'c1');
      expect(http.last!.path, '/projects/e1/claimable');
      expect(http.last!.queryParameters, {'contact_id': 'c1'});
      await repo.claimable('e1', personName: 'Mai');
      expect(http.last!.queryParameters, {'person_name': 'Mai'});

      http.body = {'debts': [], 'effects': {}, 'bills': []};
      await repo.claimBills('e1', memberId: 'm-lee', billIds: ['b1', 'b2']);
      expect(http.last!.data, {
        'member_id': 'm-lee',
        'bill_ids': ['b1', 'b2'],
      });
      await repo.claimBills(
        'e1',
        memberId: 'm-lee',
        billIds: ['b1'],
        linkTransactionId: 'tx9',
      );
      expect((http.last!.data as Map)['link_transaction_id'], 'tx9');

      // V12 settle booking answers the booked settle.
      http.body = {
        'settle': {
          'pairs': [],
          'simplified': [],
          'simplified_available': true,
          'my_settle_booking': {'booked_at': '2026-10-28T08:00:00Z'},
        },
        'effects': {},
      };
      final booked = await repo.bookEventSettle(
        'e1',
        lines: [
          {'member_id': 'm-lee', 'account_id': 'a1', 'category_id': null},
        ],
      );
      expect(http.last!.path, '/projects/e1/settle/book');
      expect(booked.myBookedAt, isNotNull);

      // Shared-bill notices / tx detail: apply and disconnect, no body.
      http.body = {
        'my_copy': {
          'connected': true,
          'transaction': {'id': 'tx1'},
        },
        'effects': {},
      };
      expect((await repo.applyEventBill('b1')).transactionId, 'tx1');
      expect(http.last!.path, '/event-bills/b1/apply');
      http.body = {'my_copy': null, 'effects': {}};
      expect((await repo.disconnectEventBill('b1')).transactionId, isNull);
      expect(http.last!.path, '/event-bills/b1/disconnect');
    },
  );
}
