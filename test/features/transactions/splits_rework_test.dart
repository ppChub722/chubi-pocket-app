import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:flutter_test/flutter_test.dart';

/// The splits rework (owner 2026-10-11): ฉัน is just another amount, the
/// split must add up exactly to save, "หารเท่ากัน" counts me in (the
/// rounding remainder is mine), and only an app-linked saved contact locks
/// its row.
void main() {
  group('balance rule', () {
    test('nobody to split with → nothing to balance', () {
      final c = DraftFormController();
      addTearDown(c.dispose);
      c.amount.text = '1,000';
      expect(c.splitsBalanced, isTrue);
      expect(c.meAmount, isNull);
    });

    test('typed ฉัน: ฉัน + the people must make the amount exactly', () {
      final c = DraftFormController();
      addTearDown(c.dispose);
      c.amount.text = '1,000';
      c.setSplits([SplitDraft(personName: 'บี', owedAmount: 300)]);

      c.setMeAmount(600);
      expect(c.meAuto, isFalse);
      expect(c.splitLeftover, 100);
      expect(c.splitsBalanced, isFalse);

      c.setMeAmount(700);
      expect(c.splitLeftover, 0);
      expect(c.splitsBalanced, isTrue);

      c.setMeAmount(800);
      expect(c.splitLeftover, -100); // over
      expect(c.splitsBalanced, isFalse);

      // Typed, it stays put: a new amount unbalances it.
      c.setMeAmount(700);
      c.amount.text = '1,200';
      expect(c.splitLeftover, 200);
      expect(c.splitsBalanced, isFalse);

      // Everyone removed → no ฉัน, nothing to balance.
      c.setSplits(const []);
      expect(c.meAmount, isNull);
      expect(c.splitsBalanced, isTrue);
    });
  });

  group('อัตโนมัติ', () {
    late DraftFormController c;
    late SplitDraft b;
    setUp(() {
      c = DraftFormController()..amount.text = '1,000';
      b = SplitDraft(personName: 'บี', owedAmount: 300);
    });
    tearDown(() => c.dispose());

    test('on by default: ฉัน is what is left, live', () {
      expect(c.meAuto, isTrue);
      c.setSplits([b]);
      expect(c.meAmount, 700);
      expect(c.splitsBalanced, isTrue);

      b.owedAmount = 450;
      c.setSplits([b]);
      expect(c.meAmount, 550);
      c.amount.text = '2,000';
      expect(c.meAmount, 1550);
      expect(c.splitsBalanced, isTrue);
    });

    test('typing ฉัน turns it off; the chip turns it back on and re-fills', () {
      c.setSplits([b]);
      c.setMeAmount(500);
      expect(c.meAuto, isFalse);
      expect(c.meAmount, 500);
      expect(c.splitLeftover, 200);

      c.setMeAuto(true);
      expect(c.meAuto, isTrue);
      expect(c.meAmount, 700);
      expect(c.splitsBalanced, isTrue);
    });

    test('the chip off keeps the number shown, as typed', () {
      c.setSplits([b]);
      c.setMeAuto(false);
      expect(c.meAmount, 700);
      b.owedAmount = 400;
      c.setSplits([b]);
      expect(c.meAmount, 700); // no longer follows
      expect(c.splitLeftover, -100);
    });

    test('the others past the cap: ฉัน 0, "แบ่งเกิน"', () {
      b.owedAmount = 1200;
      c.setSplits([b]);
      expect(c.meAmount, 0);
      expect(c.splitLeftover, -200);
      expect(c.splitsBalanced, isFalse);
    });

    test('a pending draft with splits opens on auto: ฉัน = what is left, '
        'so the hero and the rows agree (QA run-3 S2)', () {
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

    test('a loaded row comes back on auto (balanced)', () {
      c.setSplits([b]);
      c.setMeAmount(1);
      const tx = Transaction(
        id: 't1',
        accountId: null,
        type: TransactionType.expense,
        amount: 500,
        date: '2026-10-11',
        splitCount: 1,
        splits: [TxSplit(debtId: 'd1', personName: 'บี', amount: 200)],
      );
      c.prefillTransaction(tx, accounts: const [], categories: const []);
      expect(c.meAuto, isTrue);
      expect(c.meAmount, 300);
    });

    test('a saved split loads balanced (ฉัน = the rest of the share)', () {
      final c = DraftFormController();
      addTearDown(c.dispose);
      const tx = Transaction(
        id: 't1',
        accountId: null,
        type: TransactionType.expense,
        amount: 900,
        date: '2026-10-11',
        splitCount: 2,
        splits: [
          TxSplit(debtId: 'd1', personName: 'บี', amount: 300),
          TxSplit(debtId: 'd2', personName: 'ต้น', amount: 200),
        ],
      );
      c.prefillTransaction(tx, accounts: const [], categories: const []);
      expect(c.meAmount, 400);
      expect(c.splitsBalanced, isTrue);
    });

    test('an event bill: the base is the amount − the event others', () {
      final c = DraftFormController();
      addTearDown(c.dispose);
      // 1,200 bill, my share 500 → others on the event 600, my splits 100.
      const tx = Transaction(
        id: 't2',
        accountId: null,
        type: TransactionType.expense,
        amount: 1200,
        date: '2026-10-11',
        splitCount: 1,
        projectId: 'p1',
        myShare: 500,
        splits: [TxSplit(debtId: 'd1', personName: 'บี', amount: 100)],
      );
      c.prefillTransaction(tx, accounts: const [], categories: const []);
      expect(c.eventOthers, 600);
      expect(c.splitCap, 600);
      expect(c.meAmount, 500);
      expect(c.splitsBalanced, isTrue);
    });
  });

  group('หารเท่ากัน — me included', () {
    test('even: everyone the same', () {
      final r = splitEquallyWithMe(1000, 3);
      expect(r.each, 250);
      expect(r.me, 250);
    });

    test('a remainder goes on me, so nothing is left', () {
      final r = splitEquallyWithMe(100, 2);
      expect(r.each, 33.33);
      expect(r.me, 33.34);
      expect(r.each * 2 + r.me, closeTo(100, 0.0001));

      final s = splitEquallyWithMe(10, 6); // 7 ways
      expect(s.each, 1.42);
      expect(s.me, 1.48);
    });

    test('applied to the drafts: balanced', () {
      final drafts = [
        SplitDraft(personName: 'บี'),
        SplitDraft(personName: 'ต้น'),
      ];
      final r = splitEquallyWithMe(100, drafts.length);
      for (final d in drafts) {
        d.owedAmount = r.each;
      }
      expect(splitLeft(100, r.me, drafts), 0);
    });
  });

  group('lock per level', () {
    test('L1 typed name, saved: can change who, in place', () {
      final d = SplitDraft(debtId: 'd1', personName: 'ลี', owedAmount: 100);
      expect(d.identityLocked, isFalse);
      d.setPerson('ลีน่า');
      expect(d.toUpdateJson(), {
        'debt_id': 'd1',
        'owed_amount': 100.0,
        'person_name': 'ลีน่า',
      });
    });

    test('L2 plain contact, saved: can switch — back to a name drops '
        'the contact explicitly', () {
      final d = SplitDraft(
        debtId: 'd1',
        personName: 'บี',
        contactId: 'c1',
        owedAmount: 100,
      );
      expect(d.identityLocked, isFalse);
      // Another contact.
      d.setPerson('ต้น', contact: 'c2');
      expect(d.toUpdateJson(), {
        'debt_id': 'd1',
        'owed_amount': 100.0,
        'contact_id': 'c2',
        'person_name': 'ต้น',
      });
      // Back to a typed name: "contact_id": null is sent on purpose.
      d.setPerson('บีบี');
      final json = d.toUpdateJson();
      expect(json.containsKey('contact_id'), isTrue);
      expect(json['contact_id'], isNull);
      expect(json['person_name'], 'บีบี');
    });

    test('L2 unchanged: contact_id left out (= unchanged)', () {
      final d = SplitDraft(
        debtId: 'd1',
        personName: 'บี',
        contactId: 'c1',
        owedAmount: 120,
      );
      expect(d.toUpdateJson(), {'debt_id': 'd1', 'owed_amount': 120.0});
    });

    test('L3 linked to an app user, saved: locked — amount only', () {
      final d = SplitDraft(
        debtId: 'd1',
        personName: 'บี',
        contactId: 'c1',
        owedAmount: 100,
        savedContactLinked: true,
      );
      expect(d.identityLocked, isTrue);
      d.owedAmount = 80;
      expect(d.toUpdateJson(), {'debt_id': 'd1', 'owed_amount': 80.0});
    });

    test('a new row never locks, whatever its contact', () {
      final d = SplitDraft(
        personName: 'บี',
        contactId: 'c1',
        savedContactLinked: true,
      );
      expect(d.identityLocked, isFalse);
    });
  });
}
