import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/tx_rules.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx({
  String type = 'expense',
  bool author = true,
  bool? canJoin,
  bool? canEditSplits,
  double? myShare,
  List<Map<String, dynamic>> splits = const [],
}) => Transaction.fromJson({
  'id': 't1',
  'account_id': 'a1',
  'type': type,
  'amount': 300,
  'date': '2026-10-10',
  'can_edit_category': author,
  'can_join_event': ?canJoin,
  'can_edit_splits': ?canEditSplits,
  'my_share': ?myShare,
  'split_count': splits.length,
  'splits': splits,
});

void main() {
  group('the BE flags win; absent → the FE rule', () {
    test('can_join_event', () {
      expect(txCanJoinEvent(_tx()), isTrue); // fallback: my own expense
      expect(txCanJoinEvent(_tx(canJoin: false)), isFalse);
      expect(txCanJoinEvent(_tx(type: 'transfer')), isFalse);
      expect(txCanJoinEvent(_tx(author: false, canJoin: true)), isTrue);
    });

    test('can_edit_splits', () {
      expect(txCanEditSplits(_tx()), isTrue);
      expect(txCanEditSplits(_tx(author: false)), isFalse);
      expect(txCanEditSplits(_tx(canEditSplits: false)), isFalse);
      expect(txCanEditSplits(_tx(author: false, canEditSplits: true)), isTrue);
    });
  });

  group('ส่วนของคุณ: my_share as loaded, the draft once changed', () {
    DraftFormController load(Transaction t) =>
        DraftFormController()
          ..prefillTransaction(t, accounts: const [], categories: const []);

    test('as loaded → the server number', () {
      final c = load(_tx(myShare: 120));
      expect(c.savedMyShare, 120);
    });

    test('an unsaved amount or split change → null (work it out)', () {
      final c = load(
        _tx(
          myShare: 200,
          splits: [
            {'debt_id': 'd1', 'person_name': 'ลี', 'amount': 100},
          ],
        ),
      );
      expect(c.savedMyShare, 200);
      c.splits.first.owedAmount = 150;
      expect(c.savedMyShare, isNull);
      c.splits.first.owedAmount = 100;
      expect(c.savedMyShare, 200);
      c.amount.text = '400';
      expect(c.savedMyShare, isNull);
    });

    test('a BE without my_share → null', () {
      expect(load(_tx()).savedMyShare, isNull);
    });

    test('an event bill: my splits are capped at my share', () {
      // 300 bill, others on the event carry 100, my own split 50 →
      // my_share 150; the cap is 200 (forgiven splits don't count).
      final t = Transaction.fromJson({
        'id': 't1',
        'account_id': 'a1',
        'type': 'expense',
        'amount': 300,
        'date': '2026-10-10',
        'project_id': 'p1',
        'my_share': 150,
        'split_count': 2,
        'splits': [
          {'debt_id': 'd1', 'person_name': 'ลี', 'amount': 50},
          {
            'debt_id': 'd2',
            'person_name': 'มิ้น',
            'amount': 30,
            'status': 'cancelled',
          },
        ],
      });
      final c = load(t);
      expect(c.eventOthers, 100);
      expect(c.splitCap, 200);
    });

    test('off an event nothing is held back', () {
      final c = load(_tx(myShare: 300));
      expect(c.eventOthers, 0);
      expect(c.splitCap, 300);
    });
  });
}
