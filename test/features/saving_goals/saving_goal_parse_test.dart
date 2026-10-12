import 'package:chubi_pocket/features/saving_goals/domain/saving_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> base() => {
    'id': 'g1',
    'name': 'Trip',
    'target_amount': 1000,
    'allocation_pct': 50,
    'status': 'active',
    'linked_account': {
      'id': 'a1',
      'name': 'Savings',
      'type': 'savings',
      'group': 'asset',
      'currency': 'THB',
      'archived': false,
    },
    'linked_account_balance': 400.5,
  };

  test('linked account parses AccountRef without balance', () {
    final g = SavingGoal.fromJson(base());
    expect(g.linkedAccountId, 'a1');
    expect(g.linkedAccount?.name, 'Savings');
    expect(g.linkedAccount?.group, 'asset');
    expect(g.linkedAccountBalance, 400.5);
    // No own `currency` key: falls back to the ref.
    expect(g.currency, 'THB');
  });

  test('own currency wins and balance defaults to 0', () {
    final j = base()
      ..['currency'] = 'USD'
      ..remove('linked_account_balance');
    final g = SavingGoal.fromJson(j);
    expect(g.currency, 'USD');
    expect(g.linkedAccountBalance, 0);
    expect(g.copyWith(linkedAccountBalance: 5).linkedAccountBalance, 5);
  });
}
