import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/recurring_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('type filter: a pick of another type is not offered for this one', () {
    final h = RecurringLinkHandle();
    addTearDown(h.dispose);
    expect(h.candidateFor(TransactionType.income), isNull);
  });

  test('create route prefill: recurringCreateRoute carries it', () {
    final r = recurringCreateRoute(
      type: TransactionType.expense,
      amount: 3100,
      categoryId: 'c1',
      accountId: 'a1',
      name: ' Car ',
    );
    final u = Uri.parse(r);
    expect(u.path, '/recurring/new');
    expect(u.queryParameters, {
      'type': 'expense',
      'amount': '3100.0',
      'category': 'c1',
      'account': 'a1',
      'name': 'Car',
    });
  });
}
