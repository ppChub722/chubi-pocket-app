import 'package:chubi_pocket/features/accounts/domain/account_type.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart'
    show TagRef;
import 'package:chubi_pocket/features/personal_debts/domain/debt_direction.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/recurring/domain/rule_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// A หนี้ setting as the 0.4.1-2 BE answers it (BE-3 spec, kind debt).
Map<String, dynamic> _rule({String debtKind = 'repayment'}) => {
  'id': 'r1',
  'name': 'คืนแม่',
  'type': 'debt',
  'kind': 'debt',
  'amount': 300,
  'account': null,
  'category': null,
  'tags': <Object>[],
  'rule': {
    'freq': 'monthly',
    'interval': 1,
    'by_month_day': [1],
  },
  'start_date': '2026-11-01',
  'end': {'kind': 'none'},
  'status': 'paused',
  'pause_reason': 'no_balance',
  'person': {
    'name': 'แม่',
    'contact_id': 'c1',
    'icon_code': null,
    'linked': false,
    'linked_user_id': null,
  },
  'debt_kind': debtKind,
  'direction': 'paid',
  'person_balance': -250,
  'zero_rounds': 3,
};

void main() {
  test('a debt setting parses (old builds threw on type debt)', () {
    final r = Recurring.tryParse(_rule());
    expect(r, isNotNull);
    expect(r!.kind, RecurringKind.debt);
    expect(r.isDebt, isTrue);
    expect(r.type, TransactionType.expense);
    expect(r.person?.name, 'แม่');
    expect(r.debtSub, DebtEntrySub.repay);
    expect(r.direction, DebtEntryDirection.paid);
    expect(r.personBalance, -250);
    expect(r.zeroRounds, 3);
    expect(r.pauseReason, RecurringPauseReason.noBalance);
    expect(
      Recurring.fromJson(_rule(debtKind: 'debt')).debtSub,
      DebtEntrySub.record,
    );
  });

  test('a filled debt occurrence carries its person and entry', () {
    final item = RecurringItem.tryParse({
      'id': 'i1',
      'recurring_rule_id': 'r1',
      'slot': '2026-11-01',
      'stored': true,
      'date': '2026-11-01',
      'type': 'debt',
      'status': 'done',
      'amount': 250,
      'recurring': {'id': 'r1', 'name': 'คืนแม่', 'kind': 'debt'},
      'person': {'name': 'แม่', 'contact_id': 'c1', 'linked': false},
      'debt_entry': {
        'id': 'e1',
        'kind': 'repayment',
        'direction': 'paid',
        'amount': 250,
        'date': '2026-11-01',
        'transaction_id': null,
      },
    });
    expect(item, isNotNull);
    expect(item!.isDebt, isTrue);
    expect(item.recurring?.kind, RecurringKind.debt);
    expect(item.debtEntry?.id, 'e1');
    expect(item.debtEntry?.sub, DebtEntrySub.repay);
    expect(item.debtEntry?.transactionId, isNull);
  });

  test(
    'a debt rule sends person + kind + direction, never category / tags',
    () {
      // the rework: every rule carries its own target (spec §1)
      final body =
          RuleDraft.blank(RecurringKind.debt, start: DateTime(2026, 11))
              .copyWith(
                amount: 300,
                person: const EmbeddedPerson(name: 'แม่'),
                direction: DebtEntryDirection.paid,
                category: const EmbeddedCategory(
                  id: 'cat-should-not-go',
                  name: 'x',
                ),
                tags: const [TagRef(id: 't1', name: 't')],
              )
              .toJson();
      expect(body['type'], 'debt');
      expect(body['counterparty'], {'person_name': 'แม่'});
      expect(body['debt_direction'], 'paid');
      expect(body['debt_kind'], 'repayment');
      expect(body['category_id'], isNull);
      expect(body['tag_ids'], isEmpty);
      expect(body['goal_id'], isNull);
      expect(body['amount'], 300);
      expect(body['amount_mode'], 'fixed');
      expect(body['source'], {'account_id': null});
      expect((body['schedule'] as Map)['start_date'], '2026-11-01');
      expect(body['notify'], isNull, reason: 'null = the user default');
    },
  );

  test('a contact wins over the name; a plan rule sends only its plan; an '
      'asked amount never auto-accepts', () {
    final d = RuleDraft.blank(RecurringKind.debt).copyWith(
      person: const EmbeddedPerson(name: 'แม่', contactId: 'c1'),
      direction: DebtEntryDirection.received,
      debtRecord: true,
    );
    final w = d.toJson();
    expect(w['counterparty'], {'contact_id': 'c1'});
    expect(w['debt_direction'], 'received');
    expect(w['debt_kind'], 'debt');

    final plan = RuleDraft.blank(
      RecurringKind.debt,
    ).copyWith(planId: 'p1', planName: 'ผ่อนรถ').toJson();
    expect(plan['debt_plan_id'], 'p1');
    expect(plan.containsKey('counterparty'), isFalse);

    final card = RuleDraft.blank(RecurringKind.transfer).copyWith(
      ask: true,
      autoAccept: true,
      toAccount: const AccountRef(
        id: 'ktc',
        name: 'KTC',
        type: AccountType.creditCard,
      ),
    );
    final cw = card.toJson();
    expect(cw['amount_mode'], 'ask');
    expect(cw['auto_accept'], isNull);
    expect(cw['to_account_id'], 'ktc');
    expect(cw['category_id'], isNull);
  });
}
