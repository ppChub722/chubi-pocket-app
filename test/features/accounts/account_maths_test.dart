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
  test('a card in use: used credit, available, utilization', () {
    final a = _a(AccountType.creditCard, -2000, limit: 10000);
    expect(a.creditUsed, 2000);
    expect(a.creditAvailable, 8000);
    expect(a.creditUtilization, 0.2);
    expect(a.debt, 2000);
    expect(a.asset, 0);
  });

  test('an overpaid card uses no credit and is money of mine', () {
    final a = _a(AccountType.creditCard, 500, limit: 10000);
    expect(a.creditUsed, 0);
    expect(a.creditAvailable, 10000);
    expect(a.creditUtilization, 0);
    expect(a.debt, 0);
    expect(a.asset, 500);
  });

  test('an overdrawn wallet is debt, not credit', () {
    final a = _a(AccountType.bank, -300);
    expect(a.creditUsed, 0);
    expect(a.creditUtilization, isNull);
    expect(a.debt, 300);
    expect(a.asset, 0);
  });

  test('a card without a limit has no utilization', () {
    expect(_a(AccountType.creditCard, -100).creditUtilization, isNull);
    expect(_a(AccountType.creditCard, -100).creditAvailable, isNull);
  });
}
