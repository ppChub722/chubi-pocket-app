import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// The จ่ายแทน card's numbers (multi-payer, owner 2026-10-28).
const _lee = LinkPerson(name: 'Lee', contactId: 'c2');

void main() {
  group('จ่ายแทน card', () {
    test('my part fills itself with the bill minus theirs, to the satang', () {
      final link = LinkDraft()
        ..paidBy = _lee
        ..paidAmount = 33.33;
      expect(link.myPaid(100), 66.67);
      expect(link.payDiff(100), 0, reason: '✓ จ่ายครบแล้ว');
    });

    test('a typed part: over = เกินยอด (> 0), short = ยังขาด (< 0)', () {
      final link = LinkDraft()
        ..paidBy = _lee
        ..paidAmount = 40
        ..myPaidAuto = false
        ..myPaidTyped = 70;
      expect(link.payDiff(100), 10);
      link.myPaidTyped = 50;
      expect(link.payDiff(100), -10);
    });

    test('they paid it all (no amount typed): nothing from me', () {
      final link = LinkDraft()..paidBy = _lee;
      expect(link.paidAmountFor(250), 250);
      expect(link.myPaid(250), 0);
    });

    test('หารเท่ากัน: half each, an odd satang still adds up', () {
      final link = LinkDraft()..paidBy = _lee;
      link.paidEqually(100.01);
      expect(link.paidAmount! + link.myPaid(100.01), closeTo(100.01, 0.005));
      expect(link.payDiff(100.01), 0);
    });
  });
}
