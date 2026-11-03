import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
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

/// The events app: complete, delete, settle booking, my tx's paper link and
/// multi-payer lines.
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
      final booked = await repo.bookEventSettle('e1', accountId: 'a1');
      expect(http.last!.path, '/projects/e1/settle/book');
      expect(http.last!.data, {'mode': 'simplified', 'account_id': 'a1'});
      expect(booked.myBookedAt, isNotNull);

      // Tx detail: my tx follows / leaves its paper, no body.
      http.body = {'paper': {'id': 'b1'}, 'effects': {}};
      await repo.syncMyTransaction('tx1');
      expect(http.last!.path, '/transactions/tx1/paper-sync');
      await repo.unlinkMyTransaction('tx1');
      expect(http.last!.path, '/transactions/tx1/unlink-paper');
    },
  );
}
