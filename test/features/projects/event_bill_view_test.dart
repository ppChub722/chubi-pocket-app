import 'package:chubi_pocket/features/projects/domain/event_bill.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/transaction_edit.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _member(String id, String name, {bool me = false}) => {
  'id': id,
  'user_id': me ? 'u1' : null,
  'name': name,
  'icon_code': null,
  'is_me': me,
};

/// GET /event-bills/{pt_id} (openapi EventBillView): a split bill of 300 Lee
/// paid; my share 100, not paid back.
final _viewJson = <String, dynamic>{
  'bill': {
    'id': 'b1',
    'project_id': 'p1',
    'type': 'expense',
    'amount': 300,
    'date': '2026-10-27',
    'description': 'Dinner',
    'transaction_member': _member('m2', 'Lee'),
    // Multi-payer (BillPayer): Lee 200 + Pim 100, biggest first.
    'payers': [
      {'member': _member('m2', 'Lee'), 'amount': 200},
      {'member': _member('m3', 'Pim'), 'amount': 100},
    ],
    'children': [
      {
        'id': 's1',
        'amount': 100,
        'marks': <Object>[],
        'my_mark': false,
        'paid_back': false,
        'transaction_member': _member('m1', 'Me', me: true),
      },
      {
        'id': 's2',
        'amount': 100,
        'marks': <Object>[],
        'my_mark': false,
        'paid_back': true,
        'transaction_member': _member('m3', 'Pim'),
      },
    ],
  },
  'event': {
    'id': 'p1',
    'name': 'Dinner',
    'icon_code': null,
    'status': 'active',
    'kind': 'split',
  },
  'members': [
    {..._member('m1', 'Me', me: true), 'role': 'contributor'},
    {..._member('m2', 'Lee'), 'role': 'owner', 'contact_id': 'c2'},
    {..._member('m3', 'Pim'), 'role': 'contributor'},
  ],
  'tags': <Object>[],
  'rights': {
    'can_edit': true,
    'can_delete': true,
    'can_change_payer': true,
    'can_move': false,
  },
  'my_copy': {
    'connected': true,
    'role': 'share',
    'amount': 100,
    'transaction': {
      'id': 't1',
      'type': 'expense',
      'amount': 100,
      'date': '2026-10-27',
      'private_note': 'mine',
      'event_bill': {
        'event': {
          'id': 'p1',
          'name': 'Dinner',
          'status': 'active',
          'kind': 'split',
        },
        'bill_id': 'b1',
        'linked': false,
        'kind': 'copy',
        'in_sync': false,
        'differences': [
          {'field': 'amount', 'mine': 90, 'event': 100},
        ],
        'edit_in_bill': true,
        'pending_update': true,
      },
    },
    'paid_by': _member('m2', 'Lee'),
    'paid_back_me': false,
    'debts': <Object>[],
    'in_sync': false,
    'differences': [
      {'field': 'amount', 'mine': 90, 'event': 100},
    ],
    'pending_update': true,
    'private_note': 'mine',
  },
  'updated_at': '2026-10-27T10:00:00.123456Z',
};

void main() {
  test('the bill form answer: bill + shares, split kind, rights, my copy', () {
    final v = EventBillView.fromJson(_viewJson);
    expect(v.isSplit, isTrue);
    expect(v.tree.parent.id, 'b1');
    expect([for (final c in v.tree.children) c.paidBack], [false, true]);
    expect(
      [for (final p in v.tree.parent.payers) (p.member.id, p.amount)],
      [('m2', 200.0), ('m3', 100.0)],
    );
    expect(v.members.map((m) => m.id), ['m1', 'm2', 'm3']);
    expect(v.members[1].contactId, 'c2');
    expect(v.rights.canChangePayer, isTrue);
    expect(v.rights.canMove, isFalse);
    expect(v.updatedAt, '2026-10-27T10:00:00.123456Z');
    final mine = v.myCopy!;
    expect(mine.role, MyBillRole.share);
    expect(mine.paidBy?.name, 'Lee');
    expect(mine.inSync, isFalse);
    expect(mine.differences.single.field, 'amount');
    expect(mine.pendingUpdate, isTrue);
    expect(mine.transaction?.id, 't1');
    expect(mine.transaction?.privateNote, 'mine');
    expect(mine.privateNote, 'mine');
  });

  test('no part in the bill: my_copy null; edit routes by edit_in_bill', () {
    final v = EventBillView.fromJson({..._viewJson, 'my_copy': null});
    expect(v.myCopy, isNull);
    final tx = Transaction.fromJson(
      (_viewJson['my_copy'] as Map)['transaction'] as Map<String, dynamic>,
    );
    expect(tx.eventBill?.editInBill, isTrue);
    expect(tx.eventBill?.event.isSplit, isTrue);
    expect(txEditsAsBill(tx), isTrue);
  });
}
