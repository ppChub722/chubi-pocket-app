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
  test('balance table: credit used, debt, asset', () {
    final cases = [
      (
        name: 'a card in use: what is owed is the negative balance',
        account: _a(AccountType.creditCard, -2000, limit: 10000),
        used: 2000,
        debt: 2000,
        asset: 0,
      ),
      (
        name: 'an overpaid card owes nothing and is money of mine',
        account: _a(AccountType.creditCard, 500, limit: 10000),
        used: 0,
        debt: 0,
        asset: 500,
      ),
      (
        name: 'an overdrawn wallet is debt, not credit',
        account: _a(AccountType.bank, -300),
        used: 0,
        debt: 300,
        asset: 0,
      ),
    ];
    for (final c in cases) {
      expect(c.account.creditUsed, c.used, reason: c.name);
      expect(c.account.debt, c.debt, reason: c.name);
      expect(c.account.asset, c.asset, reason: c.name);
    }
  });
}
