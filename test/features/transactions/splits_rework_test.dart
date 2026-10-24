import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:flutter_test/flutter_test.dart';

/// The splits rework (owner 2026-10-11): ฉัน is just another amount, the
/// split must add up exactly to save, "หารเท่ากัน" counts me in (the
/// rounding remainder is mine), and only an app-linked saved contact locks
/// its row.
DraftFormController _form({String amount = '1,000'}) {
  final c = DraftFormController()..amount.text = amount;
  addTearDown(c.dispose);
  return c;
}

Transaction _tx({
  required double amount,
  required List<TxSplit> splits,
  String id = 't1',
  String? projectId,
  double? myShare,
}) => Transaction(
  id: id,
  accountId: null,
  type: TransactionType.expense,
  amount: amount,
  date: '2026-10-11',
  splitCount: splits.length,
  projectId: projectId,
  myShare: myShare,
  splits: splits,
);

TxSplit _saved(String id, String name, double amount) =>
    TxSplit(debtId: id, person: EmbeddedPerson(name: name), amount: amount);

void main() {
  test('balance rule: nothing to balance alone; typed ฉัน must add up', () {
    final alone = _form();
    expect(alone.splitsBalanced, isTrue);
    expect(alone.meAmount, isNull);

    final c = _form();
    c.setSplits([SplitDraft(personName: 'บี', owedAmount: 300)]);

    c.setMeAmount(600);
    expect(c.meAuto, isFalse);
    expect(c.splitLeftover, 100);
    expect(c.splitsBalanced, isFalse);

    c.setMeAmount(700);
    expect(c.splitLeftover, 0);
    expect(c.splitsBalanced, isTrue);

    c.setMeAmount(800);
    expect(c.splitLeftover, -100);
    expect(c.splitsBalanced, isFalse);

    // Typed, it stays put: a new amount unbalances it.
    c.setMeAmount(700);
    c.amount.text = '1,200';
    expect(c.splitLeftover, 200);
    expect(c.splitsBalanced, isFalse);

    c.setSplits(const []);
    expect(c.meAmount, isNull);
    expect(c.splitsBalanced, isTrue);
  });

  test('อัตโนมัติ: on by default, typing turns it off, the chip re-fills', () {
    final on = _form();
    final b = SplitDraft(personName: 'บี', owedAmount: 300);
    expect(on.meAuto, isTrue);
    on.setSplits([b]);
    expect(on.meAmount, 700);
    expect(on.splitsBalanced, isTrue);
    b.owedAmount = 450;
    on.setSplits([b]);
    expect(on.meAmount, 550);
    on.amount.text = '2,000';
    expect(on.meAmount, 1550);
    expect(on.splitsBalanced, isTrue);

    final typed = _form();
    typed.setSplits([SplitDraft(personName: 'บี', owedAmount: 300)]);
    typed.setMeAmount(500);
    expect(typed.meAuto, isFalse);
    expect(typed.meAmount, 500);
    expect(typed.splitLeftover, 200);
    typed.setMeAuto(true);
    expect(typed.meAuto, isTrue);
    expect(typed.meAmount, 700);
    expect(typed.splitsBalanced, isTrue);

    final off = _form();
    final o = SplitDraft(personName: 'บี', owedAmount: 300);
    off.setSplits([o]);
    off.setMeAuto(false);
    expect(off.meAmount, 700);
    o.owedAmount = 400;
    off.setSplits([o]);
    expect(off.meAmount, 700);
    expect(off.splitLeftover, -100);
  });

  test('the others past the cap: ฉัน 0, "แบ่งเกิน"', () {
    final c = _form();
    c.setSplits([SplitDraft(personName: 'บี', owedAmount: 1200)]);
    expect(c.meAmount, 0);
    expect(c.splitLeftover, -200);
    expect(c.splitsBalanced, isFalse);
  });

  test('a pending draft with splits opens on auto (QA run-3 S2)', () {
    final c = _form();
    c.prefill(
      const PendingDraft(
        amount: 600,
        splits: [
          {'person_name': 'บี', 'owed_amount': 300},
        ],
      ),
      accounts: const [],
      categories: const [],
    );
    expect(c.meAuto, isTrue);
    expect(c.meAmount, 300);
    expect(c.splitLeftover, 0);
    expect(c.splitsBalanced, isTrue);
  });

  test('loaded rows come back on auto, balanced', () {
    final typed = _form();
    typed.setSplits([SplitDraft(personName: 'บี', owedAmount: 300)]);
    typed.setMeAmount(1);
    typed.prefillTransaction(
      _tx(amount: 500, splits: [_saved('d1', 'บี', 200)]),
      accounts: const [],
      categories: const [],
    );
    expect(typed.meAuto, isTrue);
    expect(typed.meAmount, 300);

    final two = _form();
    two.prefillTransaction(
      _tx(
        amount: 900,
        splits: [_saved('d1', 'บี', 300), _saved('d2', 'ต้น', 200)],
      ),
      accounts: const [],
      categories: const [],
    );
    expect(two.meAmount, 400);
    expect(two.splitsBalanced, isTrue);
  });

  test('an event bill: the base is the amount − the event others', () {
    final c = _form();
    // 1,200 bill, my share 500 → others on the event 600, my splits 100.
    c.prefillTransaction(
      _tx(
        id: 't2',
        amount: 1200,
        projectId: 'p1',
        myShare: 500,
        splits: [_saved('d1', 'บี', 100)],
      ),
      accounts: const [],
      categories: const [],
    );
    expect(c.eventOthers, 600);
    expect(c.splitCap, 600);
    expect(c.meAmount, 500);
    expect(c.splitsBalanced, isTrue);
  });

  test('หารเท่ากัน counts me in; the rounding remainder is mine', () {
    final even = splitEquallyWithMe(1000, 3);
    expect(even.each, 250);
    expect(even.me, 250);

    final r = splitEquallyWithMe(100, 2);
    expect(r.each, 33.33);
    expect(r.me, 33.34);
    expect(r.each * 2 + r.me, closeTo(100, 0.0001));
    final s = splitEquallyWithMe(10, 6);
    expect(s.each, 1.42);
    expect(s.me, 1.48);

    final drafts = [
      SplitDraft(personName: 'บี'),
      SplitDraft(personName: 'ต้น'),
    ];
    final applied = splitEquallyWithMe(100, drafts.length);
    for (final d in drafts) {
      d.owedAmount = applied.each;
    }
    expect(splitLeft(100, applied.me, drafts), 0);
  });
}
