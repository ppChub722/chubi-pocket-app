import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// A จ่ายแทน row as the BE answers it (B1): bill 123, Lee paid 13.
final _paidJson = {
  'id': 't1',
  'type': 'expense',
  'amount': 123,
  'date': '2026-10-21',
  'link_mode': 'paid',
  'wallet_amount': 110,
  'paid_by': {
    'debt_id': 'd1',
    'key': 'c:c2',
    'person': {'name': 'Lee', 'contact_id': 'c2', 'linked': false},
    'amount': 13,
    'my_paid': 110,
    'source': 'me',
    'paid': false,
  },
};

/// My copy of an event bill Lee paid (B2): bill 300, three of us.
final _eventJson = {
  'id': 't2',
  'type': 'expense',
  'amount': 100,
  'date': '2026-10-21',
  'link_mode': 'event',
  'event_bill': {
    'event': {'id': 'p1', 'name': 'Khao Yai'},
    'bill_id': 'b1',
    'linked': false,
    'payer': {
      'id': 'm2',
      'user_id': null,
      'name': 'Lee',
      'icon_code': null,
      'is_me': false,
    },
    'bill_amount': 300,
    'members': [
      {
        'member': {
          'id': 'm2',
          'user_id': null,
          'name': 'Lee',
          'icon_code': null,
          'is_me': false,
        },
        'share': 100,
      },
      {
        'member': {
          'id': 'm1',
          'user_id': 'u1',
          'name': 'Me',
          'icon_code': null,
          'is_me': true,
        },
        'share': 100,
      },
      {
        'member': {
          'id': 'm3',
          'user_id': null,
          'name': 'Boss',
          'icon_code': null,
          'is_me': false,
        },
        'share': 100,
      },
    ],
  },
};

void main() {
  group('read (B1 / B2)', () {
    test('parse table', () {
      final cases = <({
        String name,
        Map<String, dynamic> json,
        void Function(Transaction tx) check,
      })>[
        (
          name: 'a จ่ายแทน row',
          json: _paidJson,
          check: (tx) {
            expect(tx.linkMode, LinkMode.paid);
            expect(tx.walletAmount, 110);
            final p = tx.paidBy!;
            expect(p.person.name, 'Lee');
            expect(p.amount, 13);
            expect(p.myPaid, 110);
            expect(p.fromPartner, isFalse);
            expect(p.key, 'c:c2');
          },
        ),
        (
          name: 'an event bill someone else paid',
          json: _eventJson,
          check: (tx) {
            expect(tx.linkMode, LinkMode.event);
            final bill = tx.eventBill!;
            expect(bill.linked, isFalse);
            expect(bill.payer!.name, 'Lee');
            expect(bill.billAmount, 300);
            expect(bill.members, hasLength(3));
            expect(bill.members![1].member.isMe, isTrue);
          },
        ),
        (
          name: 'a list row (no B1 / B2 data) still reads',
          json: {
            'id': 't3',
            'type': 'expense',
            'amount': 5,
            'date': '2026-10-21',
            'event_bill': {
              'event': {'id': 'p1', 'name': 'X'},
              'bill_id': 'b1',
              'linked': true,
              'payer': null,
              'bill_amount': 0,
              'members': null,
            },
          },
          check: (tx) {
            expect(tx.linkMode, isNull);
            expect(tx.paidBy, isNull);
            expect(tx.eventBill!.payer, isNull);
            expect(tx.eventBill!.members, isNull);
          },
        ),
      ];
      for (final c in cases) {
        try {
          c.check(Transaction.fromJson(c.json));
        } on TestFailure catch (e) {
          fail('${c.name}: ${e.message}');
        }
      }
    });

    test('B3: kind, in_sync, differences; the preview; person_balances', () {
      final bill = EventBillLink.fromJson({
        'event': {'id': 'p1', 'name': 'X'},
        'bill_id': 'b1',
        'linked': true,
        'kind': 'origin',
        'in_sync': false,
        'differences': [
          {'field': 'amount', 'mine': 100, 'event': 120},
        ],
      });
      expect(bill.isOrigin, isTrue);
      expect(bill.inSync, isFalse);
      expect(bill.differences.single.field, 'amount');
      final p = TxEditPreview.fromJson({
        'preview': true,
        'rows': <Object>[],
        'people': [
          {
            'key': 'n:bee',
            'person': {'name': 'Bee'},
            'before': 100,
            'after': 0,
            'delta': -100,
          },
        ],
        'wallets': [
          {'account_id': 'w1', 'before': 700, 'after': 750, 'delta': 50},
        ],
      });
      expect(p.people.single.name, 'Bee');
      expect(p.wallets.single.after, 750);
      final w = TransactionWriteResult.fromJson({
        'rows': <Object>[],
        'account_balances': <Object>[],
        'person_balances': [
          {
            'key': 'n:bee',
            'person': {'name': 'Bee'},
            'net': 0,
          },
        ],
      });
      expect(w.personBalances.single.key, 'n:bee');
    });
  });
}
