import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_link_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_entry.dart';
import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/debt_entry_update.dart';
import 'package:chubi_pocket/features/transactions/presentation/quick_create_bodies.dart';
import 'package:chubi_pocket/features/transactions/presentation/transaction_edit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/debt_entry_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/recurring_link.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/saving_entry_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

final _wallet = Account.fromJson({
  'id': 'w1',
  'name': 'Cash',
  'type': 'cash',
  'balance': 500,
  'currency': 'THB',
});

const _lee = LinkPerson(name: 'Lee', contactId: 'c2');
const _food = Category(id: 'cat1', name: 'Food', type: CategoryType.expense);

DraftFormController _form({
  String amount = '100',
  TransactionType type = TransactionType.expense,
  bool wallet = true,
  void Function(DraftFormController c)? set,
}) {
  final c = DraftFormController();
  addTearDown(c.dispose);
  c.amount.text = amount;
  c.date = DateTime(2026, 10, 24);
  c.setType(type);
  if (wallet) c.setAccount(_wallet);
  set?.call(c);
  return c;
}

void main() {
  test('debt description: typed on every kind, never filled in', () {
    final d = DebtEntryController(
      person: const DebtPick(
        key: 'n:lee',
        person: EmbeddedPerson(name: 'Lee'),
      ),
    );
    addTearDown(d.dispose);

    expect(d.description.text, '');
    expect(d.moneyOut, isTrue);
    d.setSub(DebtEntrySub.repay);
    expect(d.description.text, '');

    d.description.text = 'rent';
    expect(d.hasKeyData, isTrue);
    d.setSub(DebtEntrySub.record);
    d.swapDirection();
    expect(d.description.text, 'rent');
    expect(d.moneyOut, isFalse);
  });

  test('แบ่ง with another payer saves only my share, no wallet, no splits', () {
    final c = _form(
      amount: '300',
      set: (c) => c
        ..link.mode = LinkMode.split
        ..setSplits([
          SplitDraft(personName: 'Bo', owedAmount: 100),
          SplitDraft(personName: 'Lee', contactId: 'c2', owedAmount: 100),
        ])
        ..setPaidBy(_lee),
    );
    expect(c.linkMode(hasEvent: false), LinkMode.paid);
    expect(c.linkBalanced(LinkMode.paid), isTrue);

    final body = txCreateBody(c, LinkMode.paid);
    expect(body.amount, 100);
    expect(body.accountId, isNull);
    expect(body.splits, isNull);
    expect(body.link, {
      'paid_by': {'contact_id': 'c2', 'amount': 100.0},
    });

    c.setPaidBy(null);
    expect(c.linkMode(hasEvent: false), LinkMode.split);
  });

  // 0.4.1-2 SA7: แบ่ง / จ่ายแทน = ONE POST /event-bills {split: true}.
  group('split bill body', () {
    test('แบ่ง, I paid: me + each person, คืนแล้ว, my wallet', () {
      final c = _form(
        amount: '300',
        set: (c) => c
          ..link.mode = LinkMode.split
          ..setCategory(_food)
          ..setSplits([
            SplitDraft(personName: 'Bo', owedAmount: 50),
            SplitDraft(personName: 'Lee', contactId: 'c2', owedAmount: 100),
            SplitDraft(personName: 'Bo', owedAmount: 50),
          ])
          ..togglePaidBack(_lee),
      );
      final b = splitBookBodies(c, LinkMode.split)!;
      expect(b.bill['payer'], {'me': true});
      expect(b.bill['amount'], 300);
      expect(b.bill['date'], '2026-10-24');
      expect(b.bill['members'], [
        {'me': true, 'share': 100.0},
        {'person_name': 'Bo', 'share': 100.0},
        {'contact_id': 'c2', 'share': 100.0, 'paid_back': true},
      ]);
      expect(b.myBooks['account_id'], 'w1');
      expect(b.myBooks['category_id'], 'cat1');
      expect(b.myBooks['debt'], isTrue);
    });

    test('จ่ายแทน, they paid it all: payer them, my share, no wallet', () {
      final c = _form(
        amount: '300',
        set: (c) => c
          ..link.mode = LinkMode.split
          ..setSplits([
            SplitDraft(personName: 'Bo', owedAmount: 100),
            SplitDraft(personName: 'Lee', contactId: 'c2', owedAmount: 100),
          ])
          ..setPaidBy(_lee),
      );
      final b = splitBookBodies(c, LinkMode.paid)!;
      expect(b.bill['payer'], {'contact_id': 'c2'});
      expect(b.bill['members'], [
        {'me': true, 'share': 100.0},
        {'person_name': 'Bo', 'share': 100.0},
      ]);
      expect(b.myBooks['account_id'], isNull);
    });

    // SA6: "คืน X แล้ว" on my row brings my wallet back; others' too.
    test('จ่ายแทน + I paid them back: my paid_back, my wallet', () {
      final c = _form(
        amount: '300',
        set: (c) => c
          ..link.mode = LinkMode.split
          ..setSplits([
            SplitDraft(personName: 'Bo', owedAmount: 100),
            SplitDraft(personName: 'Lee', contactId: 'c2', owedAmount: 100),
          ])
          ..setPaidBy(_lee)
          ..toggleMePaidBack()
          ..togglePaidBack(const LinkPerson(name: 'Bo')),
      );
      expect(c.unpaidPayer(LinkMode.paid), isNull);
      expect(c.walletOutFor(LinkMode.paid), 100);
      final b = splitBookBodies(c, LinkMode.paid)!;
      expect(b.bill['members'], [
        {'me': true, 'share': 100.0, 'paid_back': true},
        {'person_name': 'Bo', 'share': 100.0, 'paid_back': true},
      ]);
      expect(b.myBooks['account_id'], 'w1');
      c.setPaidBy(null);
      expect(c.link.mePaidBack, isFalse);
    });

    test('not a split bill: no people, ส่วนตัว', () {
      expect(splitBookBodies(_form(), LinkMode.split), isNull);
      expect(splitBookBodies(_form(), LinkMode.personal), isNull);
    });

    // Multi-payer (owner 2026-10-28): 123 = me 110 + ลี 13, my share 123.
    test('จ่ายแทน บางส่วน: two payers, every share, my wallet', () {
      final c = _form(
        amount: '123',
        set: (c) => c
          ..link.mode = LinkMode.paid
          ..link.paidBy = _lee
          ..link.paidAmount = 13,
      );
      final b = splitBookBodies(c, LinkMode.paid)!;
      expect(b.bill.containsKey('payer'), isFalse);
      expect(b.bill['payers'], [
        {'me': true, 'amount': 110.0},
        {'contact_id': 'c2', 'amount': 13.0},
      ]);
      expect(b.bill['members'], [
        {'me': true, 'share': 123.0},
        {'contact_id': 'c2', 'share': 0.0},
      ]);
      expect(b.myBooks['account_id'], 'w1');
    });
  });

  test('quick create tx body, per ผูกกับ tab', () {
    final cases =
        <
          ({
            String name,
            DraftFormController c,
            LinkMode mode,
            String? account,
            Object? splits,
            Object? link,
          })
        >[
          (
            name: 'ส่วนตัว: a plain expense on the wallet',
            c: _form(amount: '80'),
            mode: LinkMode.personal,
            account: 'w1',
            splits: null,
            link: null,
          ),
          (
            name: 'จ่ายแทน, they paid it all: no wallet, paid_by = the bill',
            c: _form(
              amount: '123',
              set: (c) => c
                ..link.mode = LinkMode.paid
                ..link.paidBy = _lee,
            ),
            mode: LinkMode.paid,
            account: null,
            splits: null,
            link: {
              'paid_by': {'contact_id': 'c2', 'amount': 123.0},
            },
          ),
          (
            name: 'จ่ายแทน, they paid part: my part leaves the wallet',
            c: _form(
              amount: '100',
              set: (c) => c
                ..link.mode = LinkMode.paid
                ..link.paidBy = _lee
                ..link.paidAmount = 40,
            ),
            mode: LinkMode.paid,
            account: 'w1',
            splits: null,
            link: {
              'paid_by': {'contact_id': 'c2', 'amount': 40.0},
            },
          ),
          (
            name: 'แบ่ง: the complete rows only, no link',
            c: _form(
              set: (c) => c
                ..link.mode = LinkMode.split
                ..setSplits([
                  SplitDraft(personName: 'Bo', owedAmount: 30),
                  SplitDraft(personName: 'half row'),
                ]),
            ),
            mode: LinkMode.split,
            account: 'w1',
            splits: [
              {'person_name': 'Bo', 'owed_amount': 30.0, 'split_type': 'fixed'},
            ],
            link: null,
          ),
          (
            name: 'a tab not picked: today’s body, the complete splits',
            c: _form(
              set: (c) =>
                  c.setSplits([SplitDraft(personName: 'Bo', owedAmount: 30)]),
            ),
            mode: LinkMode.split,
            account: 'w1',
            splits: [
              {'person_name': 'Bo', 'owed_amount': 30.0, 'split_type': 'fixed'},
            ],
            link: null,
          ),
        ];
    for (final k in cases) {
      final b = txCreateBody(k.c, k.mode);
      expect(b.accountId, k.account, reason: k.name);
      expect(b.splits, k.splits, reason: k.name);
      expect(b.link, k.link, reason: k.name);
      expect(b.amount, k.c.amountValue, reason: k.name);
      expect(b.date, '2026-10-24', reason: k.name);
    }
  });

  test('quick create tx body: fields, transfer, trimmed text', () {
    final c = _form(
      amount: '250',
      set: (c) => c
        ..setCategory(_food)
        ..description.text = ' Lunch '
        ..note.text = '  '
        ..setTagIds({'t1', 't2'}),
    );
    final b = txCreateBody(c, LinkMode.personal);
    expect(b.type, TransactionType.expense);
    expect(b.categoryId, 'cat1');
    expect(b.description, 'Lunch');
    expect(b.note, isNull);
    expect(b.tagIds, ['t1', 't2']);
    expect(b.transferToAccountId, isNull);

    final other = Account.fromJson({
      'id': 'w2',
      'name': 'Bank',
      'type': 'bank',
      'balance': 0,
      'currency': 'THB',
    });
    final t = _form(
      type: TransactionType.transfer,
      set: (c) => c
        ..setToAccount(other)
        ..setSplits([SplitDraft(personName: 'Bo', owedAmount: 30)]),
    );
    final tb = txCreateBody(t, LinkMode.split);
    expect(tb.type, TransactionType.transfer);
    expect(tb.accountId, 'w1');
    expect(tb.transferToAccountId, 'w2');
    expect(tb.categoryId, isNull);
    expect(tb.splits, isNull);
    expect(tb.link, isNull);
  });

  // The อีเวนต์ tab's body (one /event-bills call) is in
  // event_book_body_test.dart.
  test('quick create debt record / settle / preview bodies', () {
    const lee = DebtPick(
      key: 'c:c2',
      person: EmbeddedPerson(name: 'Lee', contactId: 'c2'),
    );
    const typed = DebtPick(
      key: 'n:bo',
      person: EmbeddedPerson(name: 'Bo'),
      typedName: 'Bo',
    );
    DebtEntryController form({
      DebtPick person = lee,
      DebtEntrySub sub = DebtEntrySub.record,
      void Function(DebtEntryController d)? set,
    }) {
      final d = DebtEntryController(person: person, sub: sub);
      addTearDown(d.dispose);
      d.amount.text = '250';
      d.date = DateTime(2026, 10, 24);
      set?.call(d);
      return d;
    }

    final ledgerOnly = form(
      set: (d) => d
        ..createTransaction = false
        ..account = _wallet
        ..tagIds.add('t1')
        ..note.text = ' n '
        ..dueDate = DateTime(2026, 11, 1),
    );
    expect(debtRecordBody(ledgerOnly, lee), (
      key: 'c:c2',
      direction: DebtEntryDirection.paid,
      amount: 250.0,
      date: DateTime(2026, 10, 24),
      accountId: null,
      createTransaction: false,
      linkTransactionId: null,
      description: null,
      note: 'n',
      tagIds: null,
      personName: null,
      dueDate: DateTime(2026, 11, 1),
    ));
    final withTx = form(
      person: typed,
      set: (d) => d
        ..direction = DebtEntryDirection.received
        ..createTransaction = true
        ..account = _wallet
        ..tagIds.add('t1'),
    );
    final txBody = debtRecordBody(withTx, typed);
    expect(txBody.tagIds, ['t1']);
    expect(txBody, (
      key: 'n:bo',
      direction: DebtEntryDirection.received,
      amount: 250.0,
      date: DateTime(2026, 10, 24),
      accountId: 'w1',
      createTransaction: true,
      linkTransactionId: null,
      description: null,
      note: null,
      tagIds: txBody.tagIds,
      personName: 'Bo',
      dueDate: null,
    ));

    final settle = form(
      sub: DebtEntrySub.repay,
      set: (d) => d
        ..account = _wallet
        ..tagIds.add('t1')
        ..markPaidIds.addAll(['d1', 'd2']),
    );
    final settleBody = debtRepaymentBody(settle, lee);
    expect(settleBody.tagIds, ['t1']);
    expect(settleBody.markPaidIds, ['d1', 'd2']);
    expect(settleBody, (
      key: 'c:c2',
      kind: settle.repayKind,
      amount: 250.0,
      accountId: 'w1',
      createTransaction: true,
      linkTransactionId: null,
      date: DateTime(2026, 10, 24),
      description: null,
      note: null,
      tagIds: settleBody.tagIds,
      markPaidIds: settleBody.markPaidIds,
      markAllPaid: false,
      personName: null,
    ));
    settle.setRepayKind(DebtRepaymentKind.receive);
    expect(debtRepaymentBody(settle, lee).kind, DebtRepaymentKind.receive);

    expect(debtPreviewBody(settle, lee), (
      key: 'c:c2',
      direction: null,
      kind: DebtRepaymentKind.receive,
      amount: 250.0,
      accountId: 'w1',
      createTransaction: true,
      personName: null,
    ));

    // 0.4.1-1 D10: a repayment off "บันทึกในรายการ" is ledger-only (no
    // wallet, no tags); ปิดหนี้ rides along.
    final outside = form(
      sub: DebtEntrySub.repay,
      set: (d) => d
        ..account = _wallet
        ..tagIds.add('t1')
        ..setCreateTransaction(false)
        ..setCloseDebt(true),
    );
    final outsideBody = debtRepaymentBody(outside, lee);
    expect(outsideBody.createTransaction, isFalse);
    expect(outsideBody.accountId, isNull);
    expect(outsideBody.tagIds, isEmpty);
    expect(outsideBody.markAllPaid, isTrue);

    // An existing transaction connected: its id, no amount (its own wins),
    // no new transaction, no wallet, no tags.
    final linkTx = Transaction.fromJson({
      'id': 'tx7',
      'type': 'expense',
      'amount': 300,
      'date': '2026-10-20',
    });
    final linked = form(
      set: (d) => d
        ..account = _wallet
        ..tagIds.add('t1')
        ..setLinkedTx(linkTx),
    );
    expect(linked.amount.text, '300');
    expect(linked.date, DateTime(2026, 10, 20));
    final linkedBody = debtRecordBody(linked, lee);
    expect(linkedBody.linkTransactionId, 'tx7');
    expect(linkedBody.amount, isNull);
    expect(linkedBody.createTransaction, isFalse);
    expect(linkedBody.accountId, isNull);
    expect(linkedBody.tagIds, isNull);
    expect(debtPreviewBody(linked, lee).accountId, isNull);
    linked.clearLinkedTx();
    expect(debtRecordBody(linked, lee).createTransaction, isTrue);
    expect(debtPreviewBody(ledgerOnly, lee), (
      key: 'c:c2',
      direction: DebtEntryDirection.paid,
      kind: null,
      amount: 250.0,
      accountId: null,
      createTransaction: false,
      personName: null,
    ));
    expect(debtPreviewBody(withTx, typed).accountId, 'w1');
  });

  test('quick create saving body', () {
    final s = SavingEntryController(goalId: 'g1');
    addTearDown(s.dispose);
    s.amount.text = '500';
    s.date = DateTime(2026, 10, 4);
    s.setAccount(_wallet);
    s.note.text = '  ';
    expect(savingSaveBody(s), (
      kind: SavingEntryKind.save,
      amount: 500.0,
      date: '2026-10-04',
      goalId: 'g1',
      walletId: 'w1',
      note: null,
    ));
    s
      ..setGoal(null)
      ..setAccount(null)
      ..note.text = ' top up ';
    final b = savingSaveBody(s);
    expect(b.goalId, isNull);
    expect(b.walletId, isNull);
    expect(b.note, 'top up');
  });

  test('entry sheet: the edited body (amount, description, date)', () {
    final c = DraftFormController();
    addTearDown(c.dispose);
    c.prefill(
      const PendingDraft(
        type: TransactionType.expense,
        amount: 419,
        description: 'Netflix',
        date: '2026-11-03',
      ),
      accounts: [_wallet],
      categories: const [],
    );
    var d = c.toDraft();
    expect([d.amount, d.description, d.date], [419, 'Netflix', '2026-11-03']);
    c.amount.text = '450';
    c.description.text = 'Netflix 4K';
    c.setDate(DateTime(2026, 11, 5));
    d = c.toDraft();
    expect(
      [d.amount, d.description, d.date],
      [450, 'Netflix 4K', '2026-11-05'],
    );
  });

  group('tx edit PUT', () {
    Transaction row({String? note = 'n', String? description = 'Dinner'}) =>
        Transaction.fromJson({
          'id': 't1',
          'type': 'expense',
          'amount': 400,
          'date': '2026-10-21',
          'account': {'id': 'w1', 'name': 'Cash', 'type': 'cash'},
          'description': description,
          'note': note,
        });

    DraftFormController form(
      Transaction t, {
      void Function(DraftFormController c)? set,
    }) {
      final c = DraftFormController();
      addTearDown(c.dispose);
      c.prefillTransaction(t, accounts: [_wallet], categories: const []);
      set?.call(c);
      return c;
    }

    test('text-only edit: no link, no account change', () {
      final t = row();
      final c = form(t, set: (c) => c.description.text = 'Dinner 2');
      final b = txEditBody(
        t,
        c,
        initialAccountId: 'w1',
        initialToAccountId: null,
      );
      expect(b.description, 'Dinner 2');
      expect(b.link, isNull);
      expect(b.alsoUpdateLink, isNull);
      expect(b.accountId, isNull);
      expect(b.clearAccount, isFalse);
      expect(b.amount, 400);
      expect(b.lowering, isFalse);
    });

    test('link and also_update_link ride the PUT as given', () {
      final t = row();
      final c = form(t);
      for (final k in [
        (
          name: 'switch to personal',
          link: {'link_mode': 'personal'},
          also: null,
        ),
        (name: 'apply to the event too', link: null, also: true),
        (name: 'mine only', link: null, also: false),
      ]) {
        final b = txEditBody(
          t,
          c,
          initialAccountId: 'w1',
          initialToAccountId: null,
          alsoUpdateLink: k.also,
          link: k.link,
        );
        expect(b.link, k.link, reason: k.name);
        expect(b.alsoUpdateLink, k.also, reason: k.name);
      }
    });

    test('wallet, text and amount changes', () {
      final t = row();
      final c = form(
        t,
        set: (c) => c
          ..setAccount(null)
          ..description.text = ''
          ..note.text = ''
          ..amount.text = '300',
      );
      final b = txEditBody(
        t,
        c,
        initialAccountId: 'w1',
        initialToAccountId: null,
      );
      expect(b.clearAccount, isTrue);
      expect(b.accountId, isNull);
      expect(b.clearDescription, isTrue);
      expect(b.clearNote, isTrue);
      expect(b.lowering, isTrue);

      final moved = txEditBody(
        t,
        c..setAccount(_wallet),
        initialAccountId: 'w2',
        initialToAccountId: null,
      );
      expect(moved.accountId, 'w1');
      expect(moved.clearAccount, isFalse);
    });
  });

  test('the ask → also_update_link flag', () {
    for (final k in [
      (choice: LinkedChoice.bothSides, cancelled: false, flag: true),
      (choice: LinkedChoice.thisSideOnly, cancelled: false, flag: false),
      (choice: null, cancelled: true, flag: null),
    ]) {
      final a = linkedSaveAnswer(k.choice);
      expect(a.cancelled, k.cancelled, reason: '${k.choice}');
      expect(a.alsoUpdateLink, k.flag, reason: '${k.choice}');
    }
    final none = linkedSaveAnswer(null, asked: false);
    expect((none.cancelled, none.alsoUpdateLink), (false, null));
    expect(
      linkedSaveAsks(Transaction.fromJson(_tx())),
      isFalse,
      reason: 'a plain tx is not asked',
    );
  });

  test('debt entry PUT: only what changed', () {
    DebtEntryDraft draft({
      DebtEntryDirection direction = DebtEntryDirection.paid,
      String amount = '100',
      String description = 'lunch',
      String note = '',
      String date = '2026-10-20',
      String? accountId,
      String personKey = 'c:c2',
      List<String> tagIds = const [],
      bool paid = false,
      bool createTx = false,
      String? due,
    }) => DebtEntryDraft(
      direction: direction,
      amount: amount,
      description: description,
      note: note,
      date: date,
      accountId: accountId,
      personKey: personKey,
      tagIds: tagIds,
      paid: paid,
      createTx: createTx,
      due: due,
    );
    final day = DateTime(2026, 10, 24);
    final base = draft();
    DebtEntryUpdate put(
      DebtEntryDraft w, {
      DebtEntryDraft? o,
      bool sourced = false,
    }) => debtEntryUpdate(
      o ?? base,
      w,
      amountValue: 250,
      date: day,
      sourced: sourced,
      typedName: 'Bo',
    );

    final nothing = put(base);
    expect(nothing.direction, isNull);
    expect(nothing.amount, isNull);
    expect(nothing.date, isNull);
    expect(nothing.description, isNull);
    expect(nothing.paid, isNull);
    expect(nothing.key, isNull);
    expect(nothing.personName, isNull);
    expect(nothing.dueDate, isNull);
    expect(nothing.clearDueDate, isFalse);
    expect(nothing.createTransaction, isFalse);

    final edited = put(
      draft(
        direction: DebtEntryDirection.received,
        amount: '250',
        description: ' dinner ',
        note: ' x ',
        date: '2026-10-24',
        paid: true,
        personKey: 'n:bo',
        due: '2026-11-01',
      ),
    );
    expect(edited.direction, DebtEntryDirection.received);
    expect(edited.amount, 250);
    expect(edited.date, day);
    expect(edited.description, 'dinner');
    expect(edited.note, 'x');
    expect(edited.paid, isTrue);
    expect(edited.key, 'n:bo');
    expect(edited.personName, 'Bo');
    expect(edited.dueDate, DateTime.parse('2026-11-01'));

    final dueCleared = put(draft(), o: draft(due: '2026-11-01'));
    expect(dueCleared.clearDueDate, isTrue);
    expect(dueCleared.dueDate, isNull);

    final linked = put(draft(createTx: true, accountId: 'w1', tagIds: ['t1']));
    expect(linked.createTransaction, isTrue);
    expect(linked.accountId, 'w1');
    expect(linked.tagIds, ['t1']);
    expect(linked.clearAccount, isFalse);

    final unlinked = put(draft(), o: draft(createTx: true, accountId: 'w1'));
    expect(unlinked.createTransaction, isFalse);
    expect(unlinked.accountId, isNull);
    expect(unlinked.tagIds, isNull);

    final walletCleared = put(
      draft(createTx: true),
      o: draft(createTx: true, accountId: 'w1'),
    );
    expect(walletCleared.clearAccount, isTrue);
    expect(walletCleared.accountId, isNull);

    final fromBill = put(draft(createTx: true), sourced: true);
    expect(fromBill.createTransaction, isNull);
  });

  group('recurring link', () {
    const taken = ApiException(
      code: 'ITEM_ALREADY_LINKED',
      message: 'taken',
      statusCode: 409,
    );
    final setting = {
      'id': '1',
      'name': 'Car',
      'type': 'expense',
      'amount': 3023,
      'status': 'active',
      'start_date': '2026-09-16',
      'rule': {
        'freq': 'monthly',
        'interval': 1,
        'monthly': {'mode': 'day', 'day': 16},
      },
      'current_occurrence': {
        'item_id': 'item-1',
        'date': '2026-10-16',
        'days_until': 0,
        'amount': 3023,
        'status': 'upcoming',
      },
    };
    final candidate = LinkCandidate(
      setting: Recurring.fromJson(setting),
      occurrence: LinkOccurrence.fromJson(
        setting['current_occurrence'] as Map<String, dynamic>,
      ),
    );

    ({RecurringLinkHandle h, _Repo repo, List<String> said}) open({
      (double, double)? differs,
      ApiException? linkError,
    }) {
      final repo = _Repo(differs: differs, linkError: linkError);
      final h = RecurringLinkHandle(repository: repo)..pick(candidate);
      addTearDown(h.dispose);
      return (h: h, repo: repo, said: <String>[]);
    }

    Future<LinkResult?> link(
      RecurringLinkHandle h,
      _Repo repo,
      List<String> said, {
      bool swap = false,
    }) => h.linkWith(
      repo,
      'tx-1',
      error: said.add,
      errorText: (e) => e.message,
      askSwap: (_) async => swap,
    );

    test(
      'amount differs: the question; อัปเดต = one PUT, ไม่ต้อง = none',
      () async {
        for (final update in [true, false]) {
          final o = open(differs: (3023, 3100));
          await link(o.h, o.repo, o.said);
          expect(o.repo.links, ['item-1<-tx-1']);
          final ask = o.h.ask!;
          expect((ask.ruleAmount, ask.txAmount), (3023, 3100));
          await o.h.answerWith(
            o.repo,
            update: update,
            error: o.said.add,
            done: o.said.add,
            doneText: 'updated',
            errorText: (e) => e.message,
          );
          expect(o.repo.puts, update ? [('1', 3100.0)] : isEmpty);
          expect(o.said, update ? ['updated'] : isEmpty);
          expect(o.h.ask, isNull);
        }
      },
    );

    test('same amount: no question', () async {
      final o = open();
      await link(o.h, o.repo, o.said);
      expect(o.h.ask, isNull);
    });

    test(
      '409 taken: no = its message, swap = linked again with replace',
      () async {
        final no = open(linkError: taken);
        expect(await link(no.h, no.repo, no.said), isNull);
        expect(no.repo.links, ['item-1<-tx-1']);
        expect(no.said, ['taken']);

        final yes = open(linkError: taken);
        expect(await link(yes.h, yes.repo, yes.said, swap: true), isNotNull);
        expect(yes.repo.links, ['item-1<-tx-1', 'item-1<-tx-1 (replace)']);
        expect(yes.said, isEmpty);
      },
    );

    test('moving off its own old occurrence replaces without asking', () async {
      final o = open(linkError: taken);
      final r = await o.h.linkWith(
        o.repo,
        'tx-1',
        error: o.said.add,
        errorText: (e) => e.message,
        askSwap: (_) async => fail('must not ask'),
        replace: true,
      );
      expect(r, isNotNull);
      expect(o.repo.links, ['item-1<-tx-1 (replace)']);
    });

    test(
      'unlink = ONE call (by slot when it has one); failure says why',
      () async {
        final o = open();
        var unlinked = 0;
        for (final link in [
          const RecurringItemLink(itemId: 'item-1'),
          const RecurringItemLink(
            itemId: 'x',
            recurringId: 'r1',
            slot: '2026-10-16',
          ),
        ]) {
          await o.h.unlinkWith(
            o.repo,
            link,
            onUnlinked: () => unlinked++,
            error: o.said.add,
            errorText: (e) => e.message,
          );
        }
        expect(o.repo.unlinks, ['item-1', 'slot:r1:2026-10-16']);
        expect(unlinked, 2);

        final bad = open();
        bad.repo.unlinkError = const ApiException(
          code: 'VALIDATION_ERROR',
          message: 'no linked transaction',
          statusCode: 400,
        );
        final ok = await bad.h.unlinkWith(
          bad.repo,
          const RecurringItemLink(itemId: 'item-1'),
          onUnlinked: () => fail('must not run'),
          error: bad.said.add,
          errorText: (e) => e.message,
        );
        expect(ok, isFalse);
        expect(bad.said, ['no linked transaction']);
      },
    );
  });
}

Map<String, dynamic> _tx() => {
  'id': 't1',
  'type': 'expense',
  'amount': 10,
  'date': '2026-10-21',
};

class _Repo implements RecurringLinkRepository {
  _Repo({this.differs, this.linkError});

  final (double, double)? differs;
  final ApiException? linkError;
  final links = <String>[];
  final puts = <(String, double)>[];
  final unlinks = <String>[];
  ApiException? unlinkError;

  @override
  Future<RecurringItem> unlink(String itemId) async {
    unlinks.add(itemId);
    if (unlinkError != null) throw unlinkError!;
    return RecurringItem.fromJson({
      'id': itemId,
      'seq': 2,
      'total': 12,
      'date': '2026-10-16',
      'days_until': 0,
      'type': 'expense',
      'amount': 3023,
      'status': 'not_created',
      'tags': <dynamic>[],
    });
  }

  @override
  Future<RecurringItem> unlinkOccurrence(String ruleId, String slot) =>
      unlink('slot:$ruleId:$slot');

  @override
  Future<LinkResult> linkOccurrence(
    String ruleId,
    String slot,
    String transactionId, {
    bool replace = false,
  }) => link('slot:$ruleId:$slot', transactionId, replace: replace);

  @override
  Future<LinkResult> link(
    String itemId,
    String transactionId, {
    bool replace = false,
  }) async {
    links.add('$itemId<-$transactionId${replace ? ' (replace)' : ''}');
    if (linkError != null && !replace) throw linkError!;
    return LinkResult(
      transaction: null,
      amountDiffers: differs != null,
      ruleAmount: differs?.$1,
      transactionAmount: differs?.$2 ?? 0,
    );
  }

  @override
  Future<void> updateAmount(String recurringId, double amount) async =>
      puts.add((recurringId, amount));
}
