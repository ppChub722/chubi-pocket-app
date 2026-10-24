import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/tx_rules.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx({
  String type = 'expense',
  bool author = true,
  bool locked = false,
  String? repays,
  bool? canJoin,
  bool? canEditSplits,
  double? myShare,
  List<Map<String, dynamic>> splits = const [],
}) => Transaction.fromJson({
  'id': 't1',
  'account': {'id': 'a1', 'name': 'A'},
  'type': type,
  'amount': 300,
  'date': '2026-10-10',
  'can_edit_category': author,
  'is_locked': locked,
  if (repays != null)
    'counterparty': {
      'entry_id': repays,
      'key': 'n:bee',
      'person': {'name': 'Bee'},
      'direction': 'paid',
      'paid': false,
    },
  'can_join_event': ?canJoin,
  'can_edit_splits': ?canEditSplits,
  'my_share': ?myShare,
  'split_count': splits.length,
  'splits': splits,
});

DraftFormController _load(Transaction t) =>
    DraftFormController()
      ..prefillTransaction(t, accounts: const [], categories: const []);

void main() {
  test('txCanJoinEvent: own expense / income yes; the rest no', () {
    const system = Category(
      id: 'c',
      name: 'Opening Balance',
      type: CategoryType.income,
      isSystem: true,
    );
    final cases =
        <({String name, Transaction tx, Category? category, bool want})>[
          (name: 'own expense', tx: _tx(), category: null, want: true),
          (
            name: 'own income',
            tx: _tx(type: 'income'),
            category: null,
            want: true,
          ),
          (
            name: 'transfer',
            tx: _tx(type: 'transfer'),
            category: null,
            want: false,
          ),
          (
            name: 'other member',
            tx: _tx(author: false),
            category: null,
            want: false,
          ),
          (name: 'locked', tx: _tx(locked: true), category: null, want: false),
          (
            name: 'debt entry',
            tx: _tx(repays: 'd1'),
            category: null,
            want: false,
          ),
          (name: 'system category', tx: _tx(), category: system, want: false),
        ];
    for (final c in cases) {
      expect(
        txCanJoinEvent(c.tx, category: c.category),
        c.want,
        reason: c.name,
      );
    }
  });

  test('the BE flags win; absent → the FE rule', () {
    final cases = <({String name, bool Function() got, bool want})>[
      (
        name: 'can_join_event: fallback, my own expense',
        got: () => txCanJoinEvent(_tx()),
        want: true,
      ),
      (
        name: 'can_join_event: false',
        got: () => txCanJoinEvent(_tx(canJoin: false)),
        want: false,
      ),
      (
        name: 'can_join_event: transfer fallback',
        got: () => txCanJoinEvent(_tx(type: 'transfer')),
        want: false,
      ),
      (
        name: 'can_join_event: flag beats author',
        got: () => txCanJoinEvent(_tx(author: false, canJoin: true)),
        want: true,
      ),
      (
        name: 'can_edit_splits: fallback, author',
        got: () => txCanEditSplits(_tx()),
        want: true,
      ),
      (
        name: 'can_edit_splits: fallback, not author',
        got: () => txCanEditSplits(_tx(author: false)),
        want: false,
      ),
      (
        name: 'can_edit_splits: false',
        got: () => txCanEditSplits(_tx(canEditSplits: false)),
        want: false,
      ),
      (
        name: 'can_edit_splits: flag beats author',
        got: () => txCanEditSplits(_tx(author: false, canEditSplits: true)),
        want: true,
      ),
    ];
    for (final c in cases) {
      expect(c.got(), c.want, reason: c.name);
    }
  });

  test('ส่วนของคุณ: my_share as loaded, null once changed or absent', () {
    final cases =
        <
          ({
            String name,
            Transaction tx,
            List<(void Function(DraftFormController), double?)> steps,
          })
        >[
          (
            name: 'as loaded → the server number',
            tx: _tx(myShare: 120),
            steps: [((_) {}, 120)],
          ),
          (
            name: 'an unsaved amount or split change → null (work it out)',
            tx: _tx(
              myShare: 200,
              splits: [
                {'debt_id': 'd1', 'person_name': 'ลี', 'amount': 100},
              ],
            ),
            steps: [
              ((_) {}, 200),
              ((c) => c.splits.first.owedAmount = 150, null),
              ((c) => c.splits.first.owedAmount = 100, 200),
              ((c) => c.amount.text = '400', null),
            ],
          ),
          (
            name: 'a BE without my_share → null',
            tx: _tx(),
            steps: [((_) {}, null)],
          ),
        ];
    for (final k in cases) {
      final c = _load(k.tx);
      for (final (change, want) in k.steps) {
        change(c);
        expect(c.savedMyShare, want, reason: k.name);
      }
    }
  });

  test('split cap: event bill capped at my share; off an event, none', () {
    final cases = <({String name, Transaction tx, double others, double cap})>[
      (
        // 300 bill, others on the event carry 100, my own split 50 →
        // my_share 150; the cap is 200 (forgiven splits don't count).
        name: 'an event bill: my splits are capped at my share',
        tx: Transaction.fromJson({
          'id': 't1',
          'account': {'id': 'a1', 'name': 'A'},
          'type': 'expense',
          'amount': 300,
          'date': '2026-10-10',
          'project': {'id': 'p1', 'name': 'E'},
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
        }),
        others: 100,
        cap: 200,
      ),
      (
        name: 'off an event nothing is held back',
        tx: _tx(myShare: 300),
        others: 0,
        cap: 300,
      ),
    ];
    for (final k in cases) {
      final c = _load(k.tx);
      expect(c.eventOthers, k.others, reason: k.name);
      expect(c.splitCap, k.cap, reason: k.name);
    }
  });
}
