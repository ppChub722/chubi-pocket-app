import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repayments are person-book rows like debts (0.4.1-1 D3), a transaction
/// optional: the BE's shapes parse (openapi.yaml: DebtStatementItem,
/// Transaction.counterparty (DebtLink kind / connected), DebtEntryWriteResult,
/// person_balance on PUT / DELETE /transactions).
void main() {
  Map<String, dynamic> person({num net = 0}) => {
    'key': 'c:c1',
    'person': {'name': 'Mom', 'contact_id': 'c1'},
    'net': net,
    'open_count': 0,
    'entry_count': 3,
  };

  Map<String, dynamic> link({
    String kind = 'repayment',
    bool connected = false,
  }) => {
    'entry_id': 'r1',
    'kind': kind,
    'connected': connected,
    'key': 'c:c1',
    'person': {'name': 'Mom', 'contact_id': 'c1'},
    'direction': 'received',
    'paid': false,
  };

  Map<String, dynamic> tx({Map<String, dynamic>? counterparty}) => {
    'id': 't9',
    'type': 'income',
    'account': {'id': 'w1', 'name': 'KBank'},
    'amount': 82,
    'date': '2026-10-21',
    'counterparty': counterparty ?? link(),
  };

  Map<String, dynamic> entry({String kind = 'repayment', Object? tx}) => {
    'id': 'r1',
    'kind': kind,
    'key': 'c:c1',
    'direction': 'received',
    'amount': 82,
    'date': '2026-10-21',
    'description': null,
    'note': null,
    'paid': false,
    'source': null,
    'transaction': tx,
    'origin': null,
  };

  test('a statement line says whether it is a debt or a repayment', () {
    final page = DebtPersonDetail.fromJson({
      ...person(net: 118),
      'items': [
        {
          ...entry(
            tx: {
              'id': 't9',
              'account': {'id': 'w1', 'name': 'KBank'},
              'connected': true,
            },
          ),
          'signed_amount': -82,
          'paid': null,
        },
        {
          ...entry(kind: 'debt'),
          'id': 'e1',
          'direction': 'paid',
          'amount': 200,
          'signed_amount': 200,
        },
        // A repayment "paid outside the app": no transaction.
        {...entry(), 'id': 'r2', 'paid': null},
      ],
      'pagination': {'page': 1, 'per_page': 30, 'total': 3, 'total_pages': 1},
    });
    final [repayment, debt, outside] = page.entries.items;
    expect(repayment.isRepayment, isTrue);
    expect(repayment.id, 'r1'); // the entry id: it opens /personal-debts/r1
    expect(repayment.paid, isFalse); // null on a repayment
    expect(repayment.transaction?.connected, isTrue);
    expect(debt.isRepayment, isFalse);
    expect(debt.transaction, isNull);
    expect(outside.isRepayment, isTrue);
    expect(outside.transaction, isNull);
  });

  test('a transaction carries its person-book link, debt or repayment', () {
    final t = Transaction.fromJson(tx());
    expect(t.isRepayment, isTrue);
    expect(t.isDebtEntry, isFalse);
    expect(t.counterparty, isNull);
    expect(t.repaymentPerson!.key, 'c:c1');
    expect(t.repaymentPerson!.name, 'Mom');
    expect(t.repaymentPerson!.entryId, 'r1');
    expect(t.repaymentPerson!.person.contactId, 'c1');
    // copyWith keeps it.
    expect(t.copyWith(amount: 90).repaymentPerson, t.repaymentPerson);

    final d = Transaction.fromJson(
      tx(counterparty: link(kind: 'debt', connected: true)),
    );
    expect(d.isDebtEntry, isTrue);
    expect(d.isRepayment, isFalse);
    expect(d.repaymentPerson, isNull);
    expect(d.counterparty!.connected, isTrue);

    final plain = Transaction.fromJson({...tx(), 'counterparty': null});
    expect(plain.isRepayment, isFalse);
    expect(plain.isDebtEntry, isFalse);
  });

  test('repayment answers: POST the entry (tx optional), balance, wallets; '
      'PUT / DELETE the person balance', () {
    final r = DebtEntryWriteResult.fromJson({
      'entry': entry(tx: {'id': 't9', 'account': null, 'connected': false}),
      'item': {...entry(), 'running_balance': 118},
      'transaction': tx(),
      'person_balance': person(net: 118),
      'previous_person_balance': null,
      'balance_change': null,
      'account_balances': [
        {'account_id': 'w1', 'balance': 1082},
      ],
    });
    expect(r.entry.isRepayment, isTrue);
    expect(r.item?.runningBalance, 118);
    expect(r.transaction?.id, 't9');
    expect(r.balance.net, 118);
    expect(r.accountBalances, {'w1': 1082});

    final ledgerOnly = DebtEntryWriteResult.fromJson({
      'entry': entry(),
      'item': null,
      'transaction': null,
      'person_balance': person(net: 118),
      'account_balances': <Object>[],
    });
    expect(ledgerOnly.transaction, isNull);
    expect(ledgerOnly.item, isNull);

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
