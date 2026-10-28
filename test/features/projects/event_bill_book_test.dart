import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:flutter_test/flutter_test.dart';

import 'event_fixtures.dart';

/// 0.4.1-1 E8: the bill sheet saves in ONE call (POST / PUT /event-bills);
/// its answer and its `?preview=true` parse (openapi: EventBillBookResult,
/// EventBillBookPreview).
void main() {
  test('the book-bill answer: the patch and my tx (effects go to the bus)', () {
    final r = EventBillBookResult.fromJson({
      ...patchJson(),
      'my_books': {'tx': true, 'debt': true},
      'paybacks': <Object>[],
      'transaction_id': 'tx9',
      'account_balances': [
        {'account_id': 'w1', 'balance': 500},
      ],
      'effects': {
        'transactions': <Object>[],
        'removed_transaction_ids': <Object>[],
        'debts': <Object>[],
        'removed_debt_ids': <Object>[],
        'slots': <Object>[],
        'bills': <Object>[],
        'removed_bill_ids': <Object>[],
        'person_balances': [
          {
            'key': 'c:c2',
            'person': {'name': 'Lee', 'contact_id': 'c2'},
            'net': 150,
          },
        ],
        'account_balances': [
          {'account_id': 'w1', 'balance': 450},
          {'account_id': 'w2', 'balance': 80},
        ],
      },
    });
    expect(r.transactionId, 'tx9');
    expect(r.patch.project.id, isNotEmpty);
    expect(r.patch.accountBalances, {'w1': 500});

    final none = EventBillBookResult.fromJson({
      ...patchJson(),
      'transaction_id': null,
    });
    expect(none.transactionId, isNull);
  });

  test('the preview: people and wallets before → after, the debt default', () {
    final p = EventBillBookPreview.fromJson({
      'preview': true,
      'people': [
        {
          'key': 'c:c2',
          'person': {'name': 'Lee'},
          'before': 0,
          'after': -150,
          'delta': -150,
          'side_before': 'clear',
          'side_after': 'payable',
          'flipped': false,
        },
      ],
      'wallets': [
        {'account_id': 'w1', 'before': 600, 'after': 450, 'delta': -150},
      ],
      'debt_default': false,
    });
    expect(p.people['c:c2'], (before: 0.0, after: -150.0));
    expect(p.wallets['w1'], (before: 600.0, after: 450.0));
    expect(p.debtDefault, isFalse);
  });

  // 0.4.1-2 X1: the sheet opens with "คืนแล้ว" as saved, else an edit sends
  // paid_back:false and the BE removes the payback.
  test('a bill row: each split keeps its paid_back (BoardSplit)', () {
    final rows = ProjectTransaction.flatten({
      'id': 'b1',
      'project_id': 'p1',
      'type': 'expense',
      'amount': 300,
      'date': '2026-10-27',
      'children': [
        {'id': 's1', 'amount': 100, 'marks': <Object>[], 'paid_back': true},
        {'id': 's2', 'amount': 100, 'marks': <Object>[], 'paid_back': false},
        {'id': 's3', 'amount': 100, 'marks': <Object>[]},
      ],
    });
    expect([for (final r in rows) r.paidBack], [false, true, false, false]);
  });
}
