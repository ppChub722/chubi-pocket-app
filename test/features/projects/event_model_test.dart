import 'package:chubi_pocket/features/contacts/presentation/widgets/contact_picker.dart';
import 'package:chubi_pocket/features/projects/domain/claim.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/projects/presentation/event_assign.dart';
import 'package:chubi_pocket/features/projects/presentation/widgets/project_common.dart';
import 'package:chubi_pocket/features/projects/presentation/widgets/project_tx_tiles.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/widgets.dart';
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

  group('V3 completed = locked for good', () {
    ProjectView viewWith(Map<String, dynamic> event) => ProjectView.of(
      ProjectDetail.fromJson({...detailJson(), 'event': event}),
      currentUserId: 'u-me',
    );

    test('an active owner event offers ปิดอีเวนต์ and is not locked', () {
      final v = viewWith({...eventJson(), 'can_complete': true});
      expect(v.project.canComplete, isTrue);
      expect(v.isCompleted, isFalse);
      expect(v.rowsLocked, isFalse);
    });

    test('completed_at locks the rows, also once archived', () {
      final done = {
        ...eventJson(status: 'completed'),
        'completed_at': '2026-10-27T10:00:00Z',
        'is_locked': true,
        'can_add_bill': false,
        'can_edit': false,
      };
      final v = viewWith(done);
      expect(v.project.completedAt, isNotNull);
      expect(v.isCompleted, isTrue);
      expect(v.rowsLocked, isTrue);
      expect(v.canAddTx, isFalse);
      final archived = viewWith({...done, 'status': 'archived'});
      expect(archived.isCompleted, isTrue);
      expect(archived.rowsLocked, isTrue);
    });
  });

  group('V15 removed member = empty spots', () {
    final l = lookupAppLocalizations(const Locale('th'));

    test('removed_at + empty_person_bill_count parse; the spot is empty', () {
      final d = ProjectDetail.fromJson({
        ...detailJson(),
        'event': {...eventJson(), 'empty_person_bill_count': 2},
        'members': [
          for (final m in membersJson())
            m['name'] == 'Lee'
                ? {...m, 'status': 'left', 'removed_at': '2026-10-27T09:00:00Z'}
                : m,
        ],
      });
      expect(d.project.emptyPersonBillCount, 2);
      final lee = d.members.firstWhere((m) => m.displayName == 'Lee');
      final me = d.members.firstWhere((m) => m.isMe);
      expect(lee.isRemoved, isTrue);
      expect(me.isRemoved, isFalse);
      expect(projectMemberLevel(lee), PersonLevel.empty);
      expect(projectMemberName(l, lee), l.evbEmptyPerson);
      expect(projectMemberName(l, me), me.displayName);
    });

    test('the assign body is one BillPerson: me, a contact or a name', () {
      expect(billPersonOf(const PayerMe()), {'me': true});
      expect(billPersonOf(const PayerPerson(ContactNameTyped('Mai'))), {
        'person_name': 'Mai',
      });
    });
  });

  test('V6/V9 claimable: direction, claimed, debt-type; the claim answer', () {
    final bills = ClaimableBill.listOf({
      'data': [
        {
          'pt_id': 'b1',
          'type': 'expense',
          'payback_kind': null,
          'date': '2026-10-02',
          'description': 'Dinner',
          'bill_amount': 900,
          'payer': {'id': 'm-me', 'name': 'Pond', 'is_me': true},
          'other': {'id': 'm-lee', 'name': 'Lee'},
          'direction': 'paid',
          'amount': 300,
          'my_transaction_id': 'tx1',
          'payers': [
            {
              'member': {'id': 'm-me', 'name': 'Pond', 'is_me': true},
              'amount': 600,
            },
            {
              'member': {'id': 'm-mai', 'name': 'Mai'},
              'amount': 300,
            },
          ],
          'claimed': false,
          'claimed_debt_id': null,
        },
        {
          'pt_id': 'b2',
          'type': 'payback',
          'payback_kind': 'loan',
          'date': '2026-10-03',
          'description': null,
          'bill_amount': 200,
          'payer': {'id': 'm-lee', 'name': 'Lee'},
          'other': {'id': 'm-lee', 'name': 'Lee'},
          'direction': 'received',
          'amount': 200,
          'my_transaction_id': null,
          'claimed': true,
          'claimed_debt_id': 'd9',
        },
      ],
      'totals': [],
    });
    expect(bills.map((b) => b.ptId), ['b1', 'b2']);
    expect(bills.first.theyOweMe, isTrue);
    expect(bills.first.amount, 300);
    expect(bills.first.payers.map((p) => (p.member.name, p.amount)), [
      ('Pond', 600),
      ('Mai', 300),
    ]);
    expect(bills.last.payers, isEmpty);
    expect(bills.last.theyOweMe, isFalse);
    expect(bills.last.isDebtType, isTrue);
    expect(bills.last.claimed, isTrue);
    final r = ClaimResult.fromJson({
      'debts': [
        {'id': 'd1', 'amount': 500},
      ],
      'effects': {},
      'bills': [],
    });
    expect(r.debtIds, ['d1']);
    expect(r.amount, 500);
  });

  test('V12 settle: simplified only once completed; my lines; booked', () {
    Map<String, dynamic> ref(String id, String name, {bool me = false}) => {
      'id': id,
      'name': name,
      'is_me': me,
    };
    final open = EventSettle.fromJson({
      'pairs': [
        {
          'from': ref('m-lee', 'Lee'),
          'to': ref('m-me', 'Pond', me: true),
          'amount': 300,
        },
      ],
      'simplified': [],
      'simplified_available': false,
      'my_settle_booking': null,
    });
    expect(open.simplifiedAvailable, isFalse);
    expect(open.myBookedAt, isNull);

    final done = EventSettle.fromJson({
      'pairs': [],
      'simplified': [
        {
          'from': ref('m-lee', 'Lee'),
          'to': ref('m-me', 'Pond', me: true),
          'amount': 300,
        },
        {'from': ref('m-mai', 'Mai'), 'to': ref('m-lee', 'Lee'), 'amount': 50},
      ],
      'simplified_available': true,
      'my_settle_booking': {'booked_at': '2026-10-27T10:00:00Z'},
    });
    expect(done.simplifiedAvailable, isTrue);
    expect(done.mySimplified.single.from.name, 'Lee');
    expect(done.myBookedAt, isNotNull);
  });

  test('tagIdsFor maps names (case-insensitive), unknown names left out', () {
    expect(_view().tagIdsFor(['food', 'New one']), ['t1']);
  });

  test('withEventTags: mine flags update; a deleted event tag comes off the '
      'rows; a renamed one is renamed', () {
    final v = _view().withEventTags([
      const BoardTag(id: 't1', name: 'Food', mine: true),
    ]);
    expect(v.txs.last.tagRefs.single.mine, isTrue);
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
    expect(
      (s.all, s.active, s.unsettled, s.receivable, s.payable, s.ended),
      (7, 2, 3, 2, 1, 5),
    );
  });
}
