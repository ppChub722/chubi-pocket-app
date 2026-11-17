import 'package:chubi_pocket/features/personal_debts/domain/debt_direction.dart';
import 'package:chubi_pocket/features/recurring/domain/recurrence_rule.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/features/recurring/presentation/recurring_draft.dart';
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
    'a debt write sends person + kind + direction, never category / tags',
    () {
      // 0.4.3: the item carries the counterparty and the direction; the
      // line its amount, kind and schedule.
      final body = RecurringWrite(
        name: 'คืนแม่',
        kind: RecurringKind.debt,
        categoryId: 'cat-should-not-go',
        tagIds: const ['t1'],
        personName: 'แม่',
        direction: DebtEntryDirection.paid,
        lines: [
          RecurringLineWrite(
            rule: recurrenceFromJson(
              {'freq': 'monthly', 'interval': 1},
              start: '2026-11-01',
              end: {'kind': 'none'},
            ),
            amount: 300,
            debtSub: DebtEntrySub.repay,
          ).toJson(),
        ],
      ).toJson();
      expect(body['type'], 'debt');
      expect(body['counterparty'], {
        'contact_id': null,
        'person_name': 'แม่',
        'institution_id': null,
      });
      expect(body['debt_direction'], 'paid');
      expect(body['category_id'], isNull);
      expect(body['tag_ids'], isEmpty);
      expect(body['goal_id'], isNull);
      final line = (body['lines'] as List).single as Map<String, dynamic>;
      expect(line['debt_kind'], 'repayment');
      expect(line['amount'], 300);
      expect(line['source'], {'account_id': null});
      expect((line['schedule'] as Map)['start_date'], '2026-11-01');
    },
  );

  test('the debt form: person preset, needs a person, wallet optional, the '
      'arrow sets money in / out', () {
    final preset = RecurringPreset.fromQuery({
      'kind': 'debt',
      'person_name': 'แม่',
      'contact': 'c1',
    });
    var d = RecurringDraft.blank(preset: preset);
    expect(d.isDebt, isTrue);
    expect(d.person?.contactId, 'c1');
    expect(d.personOk, isTrue);
    expect(d.walletOk, isTrue, reason: 'no wallet = ledger only');
    expect(d.type, TransactionType.expense);

    d = d.withDebt(
      direction: DebtEntryDirection.received,
      sub: DebtEntrySub.repay,
    );
    expect(d.type, TransactionType.income);
    final w = d.copyWith(amount: '300').toWrite().toJson();
    final cp = w['counterparty'] as Map<String, dynamic>;
    expect(cp['contact_id'], 'c1');
    expect(cp['person_name'], isNull, reason: 'a contact wins over the name');
    expect(w['debt_direction'], 'received');
    final line = (w['lines'] as List).single as Map<String, dynamic>;
    expect(line['debt_kind'], 'repayment');

    final empty = RecurringDraft.blank(
      preset: const RecurringPreset(kind: RecurringKind.debt),
    );
    expect(empty.personOk, isFalse);
    // Leaving the debt kind drops the person.
    final money = d.withKind(RecurringKind.subscription);
    expect(money.person, isNull);
    expect(money.withKind(RecurringKind.debt).person, isNull);
    expect(
      d.withDebt(person: const EmbeddedPerson(name: 'Lee')).person?.name,
      'Lee',
    );
  });
}
