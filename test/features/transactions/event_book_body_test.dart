import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/event_book_body.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:flutter_test/flutter_test.dart';

final _wallet = Account.fromJson({
  'id': 'w1',
  'name': 'Cash',
  'type': 'cash',
  'balance': 500,
  'currency': 'THB',
});

const _lee = LinkPerson(name: 'Lee', contactId: 'c2');
const _bo = LinkPerson(name: 'Bo');
const _food = Category(id: 'cat1', name: 'Food', type: CategoryType.expense);

DraftFormController _form(void Function(DraftFormController c) set) {
  final c = DraftFormController();
  addTearDown(c.dispose);
  c.amount.text = '300';
  c.date = DateTime(2026, 10, 24);
  c.setType(TransactionType.expense);
  c.setAccount(_wallet);
  c.setCategory(_food);
  c.link.mode = LinkMode.event;
  set(c);
  return c;
}

void main() {
  test('E8 quick create อีเวนต์: ONE book-bill body (bill + my book)', () {
    // I paid, Lee paid back on the spot, Bo owes; "จดหนี้ด้วย" on.
    final mine = _form(
      (c) => c
        ..description.text = ' Dinner '
        ..link.eventExtra.addAll([_lee, _bo])
        ..link.eventBookDebts = true
        ..togglePaidBack(_lee),
    );
    final b = eventBookBodies(mine, tagIds: ['t1']);
    expect(b.bill, {
      'kind': 'expense',
      'amount': 300.0,
      'date': '2026-10-24',
      'description': 'Dinner',
      'payer': {'me': true},
      'members': [
        {'me': true, 'share': 100.0},
        {'contact_id': 'c2', 'share': 100.0, 'paid_back': true},
        {'person_name': 'Bo', 'share': 100.0},
      ],
    });
    expect(b.myBooks, {
      'on': true,
      'tx': true,
      'debt': true,
      'account_id': 'w1',
      'category_id': 'cat1',
      'tag_ids': ['t1'],
    });

    // Lee paid: my share, no wallet; the payer is never "คืนแล้ว".
    final theyPaid = _form(
      (c) => c
        ..link.eventExtra.add(_lee)
        ..link.eventPayer = _lee
        ..togglePaidBack(_lee),
    );
    final o = eventBookBodies(theyPaid);
    expect(o.bill['payer'], {'contact_id': 'c2'});
    expect((o.bill['members'] as List).last, {
      'contact_id': 'c2',
      'share': 150.0,
    });
    expect(o.myBooks['account_id'], isNull);
    expect(o.myBooks['debt'], isFalse);
    expect(o.myBooks.containsKey('tag_ids'), isFalse);

    expect(newEventBody('Trip'), {'name': 'Trip'});
  });
}
