import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repayments are transactions tied to the person (0.4.0-3): the BE's new
/// shapes parse (openapi.yaml: DebtStatementItem, Transaction.repayment_person,
/// DebtRepaymentResult, person_balance on PUT / DELETE /transactions).
void main() {
  Map<String, dynamic> person({num net = 0}) => {
    'key': 'c:c1',
    'person': {'name': 'Mom', 'contact_id': 'c1'},
    'net': net,
    'open_count': 0,
    'entry_count': 3,
  };

  Map<String, dynamic> tx() => {
    'id': 't9',
    'type': 'income',
    'account': {'id': 'w1', 'name': 'KBank'},
    'amount': 82,
    'date': '2026-10-21',
    'repayment_person': {
      'key': 'c:c1',
      'name': 'Mom',
      'contact_id': 'c1',
      'person': {'name': 'Mom', 'contact_id': 'c1'},
    },
  };

  test('a statement line says whether it is a debt or a repayment', () {
    final page = DebtPersonDetail.fromJson({
      ...person(net: 118),
      'items': [
        {
          'kind': 'repayment',
          'id': 't9',
          'key': 'c:c1',
          'direction': 'received',
          'amount': 82,
          'signed_amount': -82,
          'date': '2026-10-21',
          'paid': null,
          'source': null,
          'transaction': {
            'id': 't9',
            'account': {'id': 'w1', 'name': 'KBank'},
          },
        },
        {
          'kind': 'debt',
          'id': 'e1',
          'key': 'c:c1',
          'direction': 'paid',
          'amount': 200,
          'signed_amount': 200,
          'date': '2026-10-20',
          'paid': false,
          'source': null,
          'transaction': null,
        },
      ],
      'pagination': {'page': 1, 'per_page': 30, 'total': 2, 'total_pages': 1},
    });
    final [repayment, debt] = page.entries.items;
    expect(repayment.isRepayment, isTrue);
    expect(repayment.id, 't9'); // the tx id: it opens /transactions/t9
    expect(repayment.paid, isFalse); // null on a repayment
    expect(debt.isRepayment, isFalse);
    expect(debt.transaction, isNull); // a ledger-only debt still opens
  });

  test('a transaction carries its repayment person', () {
    final t = Transaction.fromJson(tx());
    expect(t.isRepayment, isTrue);
    expect(t.repaymentPerson!.key, 'c:c1');
    expect(t.repaymentPerson!.name, 'Mom');
    expect(t.repaymentPerson!.person.contactId, 'c1');
    // copyWith keeps it.
    expect(t.copyWith(amount: 90).repaymentPerson, t.repaymentPerson);
    expect(
      Transaction.fromJson({...tx(), 'repayment_person': null}).isRepayment,
      isFalse,
    );
  });

  test('repayment answers: POST the tx, balance, wallets; PUT / DELETE the '
      'person balance', () {
    final r = DebtRepaymentResult.fromJson({
      'transaction': tx(),
      'item': <String, dynamic>{},
      'person_balance': person(net: 118),
      'account_balances': [
        {'account_id': 'w1', 'balance': 1082},
      ],
    });
    expect(r.transaction.id, 't9');
    expect(r.balance.net, 118);
    expect(r.accountBalances, {'w1': 1082});
    final put = TransactionWriteResult.fromJson({
      'rows': [tx()],
      'account_balances': <Object>[],
      'person_balance': person(net: 100),
    });
    expect(put.personBalance?.net, 100);
    final del = DeleteTransactionResult.fromJson({
      'id': 't9',
      'account_balances': <Object>[],
      'person_balance': person(net: 200),
    });
    expect(del.personBalance?.net, 200);
    // An ordinary row has none.
    expect(
      TransactionWriteResult.fromJson({'rows': <Object>[]}).personBalance,
      isNull,
    );
  });
}
