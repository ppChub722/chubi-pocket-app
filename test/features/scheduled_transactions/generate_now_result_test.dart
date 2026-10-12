import 'package:chubi_pocket/features/scheduled_transactions/domain/scheduled_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> body() => {
    'generated_transaction': {'id': 't1', 'amount': 10, 'date': '2026-10-12'},
    'schedule_updated': {'next_billing_date': '2026-11-12', 'status': 'active'},
  };

  test('parses account_balances', () {
    final r = GenerateNowResult.fromJson(
      body()
        ..['account_balances'] = [
          {'account_id': 'a1', 'balance': 90.5},
          {'account_id': 'a2', 'balance': 1},
        ],
    );
    expect(r.accountBalances, {'a1': 90.5, 'a2': 1.0});
  });

  test('account_balances absent -> empty', () {
    expect(GenerateNowResult.fromJson(body()).accountBalances, isEmpty);
  });
}
