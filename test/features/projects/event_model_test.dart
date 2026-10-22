import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/projects/presentation/widgets/project_common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'event_fixtures.dart';

ProjectView _view() =>
    ProjectView.of(ProjectDetail.fromJson(detailJson()), currentUserId: 'u-me');

void main() {
  group('ProjectDetail.fromJson (spec EventDetail)', () {
    test('event flags, my tags, members, summary', () {
      final d = ProjectDetail.fromJson(detailJson());
      final e = d.project;
      expect(e.name, 'Chiang Mai trip');
      expect(e.isOwner, isTrue);
      expect(e.canAddBill, isTrue);
      expect(e.myNet, 250);
      expect(e.tags.single.name, 'Trips');
      expect(d.members.map((m) => m.displayName), ['Pond', 'Lee']);
      expect(d.members.first.isMe, isTrue);
      expect(d.members.first.projectId, 'e1');
      expect(d.summary.myNet, 250);
      expect(d.summary.positions.map((p) => p.displayName), ['Pond', 'Lee']);
      expect(d.summary.byTag.first.name, 'Food');
      expect(d.summary.byTag.last.isUntagged, isTrue);
      expect(d.tags.single.id, 't1');
    });

    test('the board is flat: each bill, then its splits', () {
      final d = ProjectDetail.fromJson(detailJson());
      expect(d.transactions.map((t) => t.id), ['b1', 's1', 'b2']);
      final split = d.transactions[1];
      expect(split.parentProjectTransactionId, 'b1');
      expect(split.transactionMemberId, 'm-lee');
      expect(split.type, 'expense');
      expect(split.date, '2026-10-02');
      final bill = d.transactions.first;
      expect(bill.linked, isTrue);
      expect(bill.sourceTx?.id, 'tx9');
      expect(d.transactions.last.tags, ['Food']);
      expect(d.transactions.last.tagRefs.single.id, 't1');
      expect(buildProjectTxTree(d.transactions).first.children.length, 1);
    });
  });

  group('ProjectView.apply (EventPatch)', () {
    test('a bill edit carries my linked tx (B3 my_transaction)', () {
      final p = EventPatch.fromJson({
        ...patchJson(),
        'my_transaction': {
          'id': 'tx9',
          'type': 'expense',
          'amount': 100,
          'date': '2026-10-02',
          'event_bill': {
            'event': {'id': 'e1', 'name': 'Chiang Mai trip'},
            'bill_id': 'b1',
            'linked': false,
            'kind': 'copy',
            'in_sync': false,
            'differences': [
              {'field': 'amount', 'mine': 100, 'event': 120},
            ],
          },
        },
      });
      final mine = p.myTransaction!;
      expect(mine.id, 'tx9');
      expect(mine.eventBill!.isOrigin, isFalse);
      expect(mine.eventBill!.inSync, isFalse);
      expect(EventPatch.fromJson(patchJson()).myTransaction, isNull);
    });

    test('a changed bill replaces its old copy in place, splits too', () {
      final v = _view();
      final p = EventPatch.fromJson(
        patchJson(row: boardRowJson(marks: ['m-me'])),
      );
      final next = v.apply(p);
      expect(next.txs.map((t) => t.id), ['b1', 'b2']);
      expect(next.txs.first.isMarkedBy('m-me'), isTrue);
    });

    test('a new bill goes first; a removed one drops with its splits', () {
      final v = _view();
      final added = v.apply(
        EventPatch.fromJson(
          patchJson(
            row: boardRowJson(id: 'b3', description: 'Taxi'),
          ),
        ),
      );
      expect(added.trees.first.parent.id, 'b3');
      final removed = added.apply(
        EventPatch.fromJson(patchJson(removedRowId: 'b1', totalExpense: 750)),
      );
      expect(removed.txs.map((t) => t.id), ['b3', 'b2']);
      expect(removed.summary?.totalExpense, 750);
    });
  });

  test('tagIdsFor maps names (case-insensitive), unknown names left out', () {
    expect(_view().tagIdsFor(['food', 'New one']), ['t1']);
  });

  test('withEventTags updates the rows’ mine flags', () {
    final v = _view().withEventTags([
      const BoardTag(id: 't1', name: 'Food', mine: true),
    ]);
    expect(v.txs.last.tagRefs.single.mine, isTrue);
  });

  test('a deleted event tag comes off the rows; a renamed one is renamed', () {
    final renamed = _view().withEventTags([
      const BoardTag(id: 't1', name: 'Meals'),
    ]);
    expect(renamed.txs.last.tagRefs.single.name, 'Meals');
    expect(renamed.txs.last.tags, ['Meals']);
    final gone = _view().withEventTags(const []);
    expect(gone.txs.last.tagRefs, isEmpty);
  });

  test('0.4.0 numbers: my split, remaining, positions, list summary', () {
    final d = ProjectDetail.fromJson(detailJson());
    expect(d.project.myPaid, 1000);
    expect(d.project.myShare, 750);
    expect(d.project.myReceivable, 250);
    expect(d.project.myPayable, 0);
    expect(d.project.remaining, 8250);
    expect(d.summary.positions.last.payable, 250);
    expect(d.summary.positions.first.receivable, 250);
    final s = ProjectListSummary.fromJson(listSummaryJson());
    expect(s.myShareTotal, 14289);
    expect(s.paidTotal, 22539);
    expect(s.receivableTotal, 8250);
    expect((s.active, s.unsettled, s.ended), (2, 1, 5));
  });
}
