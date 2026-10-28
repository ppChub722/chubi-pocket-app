import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V7 a lump debt lists its bills (event / split, in sync or not); '
      'a manual debt has none', () {
    final lump = DebtEntry.fromJson({
      'id': 'd1',
      'kind': 'debt',
      'direction': 'paid',
      'amount': 500,
      'bills': [
        {
          'pt_id': 'b1',
          'event': {'id': 'e1', 'name': 'Chiang Mai', 'status': 'active'},
          'description': 'Dinner',
          'amount': 300,
          'in_sync': true,
          'differences': [],
          'edit_in_bill': true,
        },
        {
          'pt_id': 'b2',
          'event': {'id': 'h1', 'name': 'Taxi', 'kind': 'split'},
          'description': null,
          'amount': 200,
          'in_sync': false,
          'differences': [],
          'edit_in_bill': false,
        },
      ],
    });
    expect(lump.bills.map((b) => b.ptId), ['b1', 'b2']);
    expect(lump.bills.first.event.name, 'Chiang Mai');
    expect(lump.bills.first.editInBill, isTrue);
    expect(lump.bills.last.event.isSplit, isTrue);
    expect(lump.bills.last.inSync, isFalse);
    expect(lump.bills.fold<double>(0, (s, b) => s + b.amount), lump.amount);

    final manual = DebtEntry.fromJson({
      'id': 'd2',
      'direction': 'received',
      'amount': 80,
    });
    expect(manual.bills, isEmpty);
  });
}
