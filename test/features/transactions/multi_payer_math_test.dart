import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/quick_create_bodies.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:flutter_test/flutter_test.dart';

/// Multi-payer bill maths on the app side (0.4.1-2, owner 2026-10-28): the
/// จ่ายแทน card's numbers and the bill body quick create sends. Who owes whom
/// (proportional to what each payer paid) is worked out by the BE preview,
/// not here.
const _lee = LinkPerson(name: 'Lee', contactId: 'c2');

final _wallet = Account.fromJson({
  'id': 'w1',
  'name': 'Cash',
  'type': 'cash',
  'balance': 500,
  'currency': 'THB',
});

DraftFormController _form(
  String amount, {
  TransactionType type = TransactionType.expense,
  void Function(DraftFormController c)? set,
}) {
  final c = DraftFormController();
  addTearDown(c.dispose);
  c.amount.text = amount;
  c.date = DateTime(2026, 10, 28);
  c.setType(type);
  c.setAccount(_wallet);
  set?.call(c);
  return c;
}

double _sum(Object? rows, String key) => [
  for (final r in rows! as List) ((r as Map)[key] as num).toDouble(),
].fold(0.0, (a, b) => a + b);

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

  group('two-payer bill body: Σ payers = Σ shares = the bill', () {
    void expectBalanced(Map<String, dynamic> bill, double total) {
      expect(_sum(bill['payers'], 'amount'), closeTo(total, 0.005));
      expect(_sum(bill['members'], 'share'), closeTo(total, 0.005));
    }

    test('a satang split (100 = me 66.67 + Lee 33.33)', () {
      final c = _form(
        '100',
        set: (c) => c
          ..link.mode = LinkMode.paid
          ..link.paidBy = _lee
          ..link.paidAmount = 33.33,
      );
      final b = splitBookBodies(c, LinkMode.paid)!;
      expect(b.bill['payers'], [
        {'me': true, 'amount': 66.67},
        {'contact_id': 'c2', 'amount': 33.33},
      ]);
      expectBalanced(b.bill, 100);
    });

    test(
      'with people sharing the bill too (300 = me 200 + Lee 100; Bo 100)',
      () {
        final c = _form(
          '300',
          set: (c) => c
            ..link.mode = LinkMode.paid
            ..link.paidBy = _lee
            ..link.paidAmount = 100
            ..setSplits([SplitDraft(personName: 'Bo', owedAmount: 100)]),
        );
        final b = splitBookBodies(c, LinkMode.paid)!;
        expectBalanced(b.bill, 300);
        final members = (b.bill['members'] as List).cast<Map>();
        expect(
          members.where((m) => m['person_name'] == 'Bo').single['share'],
          100,
        );
        expect(b.myBooks['account_id'], 'w1', reason: 'I paid part: my wallet');
      },
    );

    test('รับแทน (an income): the same maths, kind income', () {
      final c = _form(
        '123',
        type: TransactionType.income,
        set: (c) => c
          ..link.mode = LinkMode.paid
          ..link.paidBy = _lee
          ..link.paidAmount = 13,
      );
      final b = splitBookBodies(c, LinkMode.paid)!;
      expect(b.bill['kind'], 'income');
      expect(b.bill['payers'], [
        {'me': true, 'amount': 110.0},
        {'contact_id': 'c2', 'amount': 13.0},
      ]);
      expectBalanced(b.bill, 123);
    });

    test('they paid it all: ONE payer, no payers list (their share = the '
        'rest)', () {
      final c = _form(
        '200',
        set: (c) => c
          ..link.mode = LinkMode.paid
          ..link.paidBy = _lee,
      );
      final b = splitBookBodies(c, LinkMode.paid)!;
      expect(b.bill.containsKey('payers'), isFalse);
      expect(b.bill['payer'], {'contact_id': 'c2'});
    });
  });
}
