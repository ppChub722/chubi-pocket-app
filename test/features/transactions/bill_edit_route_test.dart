import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/transaction_edit.dart';
import 'package:flutter_test/flutter_test.dart';

/// My tx that IS an event bill (I paid), in an event with [status].
Transaction _origin({String status = 'active', bool withBill = true}) =>
    Transaction.fromJson({
      'id': 't1',
      'type': 'expense',
      'amount': 300,
      'date': '2026-10-27',
      'project': {'id': 'p1', 'name': 'Khao Yai', 'status': status},
      if (withBill)
        'event_bill': {
          'event': {'id': 'p1', 'name': 'Khao Yai', 'status': status},
          'bill_id': 'b1',
          'linked': true,
          'kind': 'origin',
        },
    });

/// 0.4.1-2 SA10: a bill of an open event edits in the bill form; a completed
/// one (locked, no more sync) or a disconnected tx edits on its own.
void main() {
  test('an open event bill edits as the bill', () {
    final t = _origin();
    expect(txEditsAsBill(t), isTrue);
    expect(txLinkTabsEditable(t), isTrue);
  });

  test('a completed event: own edit, the event link locked', () {
    final t = _origin(status: 'completed');
    expect(txEditsAsBill(t), isFalse);
    expect(txLinkTabsEditable(t), isFalse);
  });

  test('no bill (disconnected): own edit', () {
    expect(txEditsAsBill(_origin(withBill: false)), isFalse);
  });
}
