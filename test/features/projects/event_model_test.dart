import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/projects/presentation/widgets/project_common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'event_fixtures.dart';

ProjectView _view() => ProjectView.of(
  ProjectDetail.fromJson(detailJson()),
  currentUserId: 'u-me',
  userCurrency: 'THB',
);

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

  test('currency is the user’s (single currency)', () {
    expect(_view().currency, 'THB');
  });
}
