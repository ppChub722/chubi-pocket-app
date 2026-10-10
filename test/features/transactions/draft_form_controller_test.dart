import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const food = Category(id: 'c1', name: 'อาหาร', type: CategoryType.expense);
  const salary = Category(
    id: 'c2',
    name: 'เงินเดือน',
    type: CategoryType.income,
  );

  test('switching type keeps the fields; the category follows the type', () {
    final c = DraftFormController();
    addTearDown(c.dispose);
    c.amount.text = '120';
    c.description.text = 'ข้าว';
    c.setCategory(food);

    c.setType(TransactionType.income);
    expect(c.category, isNull); // income has no pick yet
    expect(c.amount.text, '120');
    expect(c.description.text, 'ข้าว');
    c.setCategory(salary);

    c.setType(TransactionType.expense);
    expect(c.category, food);
    c.setType(TransactionType.income);
    expect(c.category, salary);
  });

  test('a transfer keeps the splits, just doesn\'t send them', () {
    final c = DraftFormController();
    addTearDown(c.dispose);
    c.amount.text = '300';
    c.setSplits([SplitDraft(personName: 'กุ้ง', owedAmount: 100)]);

    c.setType(TransactionType.transfer);
    expect(c.splits, hasLength(1));
    expect(c.toDraft().splits, isEmpty);

    c.setType(TransactionType.expense);
    expect(c.toDraft().splits, hasLength(1));
  });

  test('saved splits: update payload, and restore keeps what was repaid', () {
    final c = DraftFormController();
    addTearDown(c.dispose);
    const tx = Transaction(
      id: 't1',
      accountId: null,
      type: TransactionType.expense,
      amount: 300,
      date: '2026-10-10',
      splitCount: 1,
      splits: [
        TxSplit(
          debtId: 'd1',
          personName: 'มิว',
          amount: 150,
          settledAmount: 50,
        ),
      ],
    );
    c.prefillTransaction(tx, accounts: const [], categories: const []);
    final saved = c.toDraft();
    expect(c.splits.single.toUpdateJson(), {
      'debt_id': 'd1',
      'owed_amount': 150.0,
    });
    // A new person goes up like at create.
    expect(SplitDraft(personName: 'บีม', owedAmount: 80).toUpdateJson(), {
      'person_name': 'บีม',
      'owed_amount': 80.0,
    });

    c.splits.single.owedAmount = 120;
    c.restoreTransaction(saved, accounts: const [], categories: const []);
    final s = c.splits.single;
    expect(s.owedAmount, 150);
    expect(s.debtId, 'd1');
    expect(s.hasRepayments, isTrue); // can't be removed
  });
}
