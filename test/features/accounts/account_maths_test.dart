import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/domain/account_type.dart';
import 'package:flutter_test/flutter_test.dart';

Account _a(AccountType type, double balance, {double? limit}) => Account(
  id: 'a',
  name: 'a',
  type: type,
  balance: balance,
  currency: 'THB',
  creditLimit: limit,
);

void main() {
  test('a card in use: what is owed is the negative balance', () {
    final a = _a(AccountType.creditCard, -2000, limit: 10000);
    expect(a.creditUsed, 2000);
    expect(a.debt, 2000);
    expect(a.asset, 0);
  });

  test('an overpaid card owes nothing and is money of mine', () {
    final a = _a(AccountType.creditCard, 500, limit: 10000);
    expect(a.creditUsed, 0);
    expect(a.debt, 0);
    expect(a.asset, 500);
  });

  test('an overdrawn wallet is debt, not credit', () {
    final a = _a(AccountType.bank, -300);
    expect(a.creditUsed, 0);
    expect(a.debt, 300);
    expect(a.asset, 0);
  });

  test('credit used % and available come from the BE, not the client', () {
    final a = Account.fromJson({
      'id': 'c',
      'name': 'Visa',
      'type': 'credit_card',
      'balance': -2000.0,
      'currency': 'THB',
      'credit_limit': 10000.0,
      'credit_used_pct': 20,
      'credit_available': 8000.0,
    });
    expect(a.creditUsedPct, 20);
    expect(a.creditAvailable, 8000);
    final none = Account.fromJson({
      'id': 'b',
      'name': 'KBank',
      'type': 'bank',
      'balance': 1.0,
      'currency': 'THB',
    });
    expect(none.creditUsedPct, isNull);
    expect(none.creditAvailable, isNull);
  });
}
