import 'package:chubi_pocket/features/personal_debts/domain/debt_direction.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_page.dart';
import 'package:chubi_pocket/features/recurring/presentation/recurring_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// BE `ItemPage` (internal/modules/recurring/item_model.go): a debt item with
/// a plan and two lines, one paid by a person.
Map<String, dynamic> itemPageJson() => {
  'id': 'it1',
  'name': 'ผ่อนรถยนต์',
  'type': 'debt',
  'status': 'active',
  'icon_code': null,
  'category': null,
  'tags': <dynamic>[],
  'counterparty': {
    'key': 'i:inst1',
    'kind': 'institution',
    'name': 'Toyota Leasing',
    'person': null,
    'institution': {
      'id': 'inst1',
      'name': 'Toyota Leasing',
      'kind': 'finance',
      'icon_code': null,
    },
    'net': -650286,
  },
  'debt_direction': 'received',
  'plan': {
    'principal': 780000,
    'count': 48,
    'start_date': '2025-11-25',
    'interest_method': 'flat',
    'interest_rate': 2.79,
    'installment_amount': null,
    'card_account_id': null,
    'card_account': null,
    'closed': false,
    'done': 12,
    'left_count': 36,
    'paid_principal': 195000,
    'left_principal': 585000,
    'left_interest': 65286,
    'left_total': 650286,
    'last_date': '2029-10-25',
    'next': {
      'seq': 13,
      'due_date': '2026-11-25',
      'amount': 18063.5,
      'principal': 16250,
      'interest': 1813.5,
      'status': 'upcoming',
      'paid_at': null,
      'personal_debt_id': null,
      'edited': false,
    },
    'due': <dynamic>[],
    'chain': [
      {'seq': 1, 'status': 'paid'},
      {'seq': 13, 'status': 'upcoming'},
    ],
  },
  'reminders': [
    {'id': 'rm1', 'anchor': 'due', 'days_before': 3, 'time': '09:00'},
  ],
  'lines': [
    {
      'id': 'it1',
      'amount': 15000,
      'source': {'account_id': 'a1', 'paid_by': null},
      'account': {'id': 'a1', 'name': 'เงินในธนาคาร', 'type': 'bank'},
      'paid_by': null,
      'debt_kind': 'repayment',
      'schedule': {
        'freq': 'monthly',
        'interval': 1,
        'weekdays': <dynamic>[],
        'monthly': {'mode': 'day', 'day': 25},
        'dates': <dynamic>[],
        'start_date': '2025-11-25',
        'end': {'kind': 'count', 'count': 48},
      },
      'auto_create': true,
      'status': 'active',
      'next_date': '2026-11-25',
      'due_count': 0,
      'progress': {'done': 12, 'total': 48},
      'counts': {'upcoming': 36},
      'actions': {'pause': true, 'archive': true, 'extend': false},
    },
    {
      'id': 'l2',
      'amount': 3063.5,
      'source': {
        'account_id': null,
        'paid_by': {'contact_id': 'c1', 'person_name': null},
      },
      'account': null,
      'paid_by': {'name': 'แฟน', 'contact_id': 'c1'},
      'debt_kind': 'debt',
      'schedule': {
        'freq': 'monthly',
        'interval': 1,
        'start_date': '2025-11-25',
        'end': {'kind': 'none'},
      },
      'auto_create': false,
      'status': 'paused',
      'actions': {'resume': true, 'delete': true},
    },
  ],
  'stats': {'paid_count': 12, 'paid_total': 216762},
  'due_count': 0,
  'next': {
    'recurring_rule_id': 'it1',
    'date': '2026-11-25',
    'amount': 15000,
    'days_until': 8,
  },
  'month_total': 18063.5,
  'actions': {'pause': true, 'archive': true, 'add_line': true},
  'account_balances': [
    {'account_id': 'a1', 'balance': 90036.5},
  ],
};

void main() {
  test('the item page: counterparty, plan, reminders, lines', () {
    final p = RecurringPage.fromJson(itemPageJson());
    expect(p.kind, RecurringKind.debt);
    expect(p.direction, DebtEntryDirection.received);
    expect(p.counterparty?.isInstitution, isTrue);
    expect(p.counterparty?.institution?.id, 'inst1');
    expect(p.counterparty?.debtPath, '/personal-debts/people/i%3Ainst1');
    expect(p.plan?.count, 48);
    expect(p.plan?.next?.seq, 13);
    expect(p.plan?.next?.interest, 1813.5);
    expect(p.plan?.method, PlanInterestMethod.flat);
    expect(p.plan?.toMark?.seq, 13);
    expect(p.reminders.single.daysBefore, 3);
    expect(p.lines, hasLength(2));
    expect(p.lines[1].paidBy?.name, 'แฟน');
    expect(p.lines[1].status, RecurringStatus.paused);
    expect(p.actions.addLine, isTrue);
    expect(p.balances['a1'], 90036.5);
  });

  test('the item as one rule: the next line, the item id and status', () {
    final p = RecurringPage.fromJson(itemPageJson());
    expect(p.mainLine?.id, 'it1');
    final v = p.view;
    expect(v.id, 'it1');
    expect(v.name, 'ผ่อนรถยนต์');
    expect(v.amount, 15000);
    expect(v.account?.id, 'a1');
    expect(v.hasEnd, isTrue);
    expect(v.progressTotal, 48);
    expect(v.actions.pause, isTrue);
  });

  test('the form on an item: main line edited, the others sent back as is', () {
    final p = RecurringPage.fromJson(itemPageJson());
    final d = RecurringDraft.from(p.view);
    expect(d.kind, RecurringKind.debt);
    final w = d.toWrite().toJson();
    expect(w['type'], 'debt');
    // A new line from the line's input keeps the other line's id.
    expect(p.lines[1].toInput()['id'], 'l2');
    expect((p.lines[1].toInput()['source'] as Map)['paid_by'], {
      'contact_id': 'c1',
      'person_name': null,
    });
  });

  test('a card plan sends no line', () {
    final d =
        RecurringDraft.blank(
          preset: const RecurringPreset(kind: RecurringKind.debt),
        ).withPlan(
          RecurringPlanDraft(
            start: DateTime(2026, 11, 25),
            principal: '9000',
            count: 3,
            cardAccountId: 'card1',
          ),
        );
    expect(d.cardPlan, isTrue);
    final w = d.toWrite().toJson();
    expect(w['lines'], isEmpty);
    expect((w['plan'] as Map)['card_account_id'], 'card1');
    expect((w['plan'] as Map)['principal'], 9000);
  });
}
