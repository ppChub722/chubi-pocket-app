import 'package:chubi_pocket/features/personal_debts/domain/debt_direction.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_page.dart';
import 'package:chubi_pocket/features/recurring/domain/rule_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// BE `ItemPage` (internal/modules/recurring/item_model.go, the rework): a
/// recurring with a plan and two rules, one paid by a person; each rule
/// carries its own type and debt target.
const _counterparty = {
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
};

Map<String, dynamic> itemPageJson() => {
  'id': 'it1',
  'name': 'ผ่อนรถยนต์',
  'tracking_type': 'installment',
  'status': 'active',
  'icon_code': null,
  'touches': [
    {'kind': 'institution', 'id': 'inst1', 'name': 'Toyota Leasing'},
  ],
  'plan': {
    'principal': 780000,
    'count': 48,
    'start_date': '2025-11-25',
    'interest_method': 'flat',
    'interest_rate': 2.79,
    'installment_amount': null,
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
  'rules': [
    {
      'id': 'it1',
      'seq': 1,
      'type': 'debt',
      'counterparty': _counterparty,
      'debt_direction': 'received',
      'amount_mode': 'fixed',
      'amount': 15000,
      'source': {'account_id': 'a1', 'paid_by': null},
      'account': {'id': 'a1', 'name': 'เงินในธนาคาร', 'type': 'bank'},
      'paid_by': null,
      'debt_kind': 'repayment',
      'schedule': {
        'freq': 'monthly',
        'interval': 1,
        'weekdays': <dynamic>[],
        'month_days': [25],
        'dates': <dynamic>[],
        'start_date': '2025-11-25',
        'end': {'kind': 'count', 'count': 48},
      },
      'auto_accept': true,
      'notify_on': true,
      'auto_accept_on': true,
      'status': 'active',
      'next_date': '2026-11-25',
      'due_count': 0,
      'progress': {'done': 12, 'total': 48},
      'counts': {'upcoming': 36},
      'actions': {'pause': true, 'archive': true, 'extend': false},
    },
    {
      'id': 'l2',
      'seq': 2,
      'type': 'debt',
      'counterparty': _counterparty,
      'debt_direction': 'received',
      'amount_mode': 'fixed',
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
      'auto_accept': null,
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
  'actions': {'pause': true, 'archive': true, 'add_rule': true},
  'account_balances': [
    {'account_id': 'a1', 'balance': 90036.5},
  ],
};

void main() {
  test('the item page: counterparty, plan, rules', () {
    final p = RecurringPage.fromJson(itemPageJson());
    expect(p.kind, RecurringKind.debt);
    expect(p.trackingType, 'installment');
    expect(p.touches.single.kind, 'institution');
    expect(p.direction, DebtEntryDirection.received);
    expect(p.counterparty?.isInstitution, isTrue);
    expect(p.counterparty?.institution?.id, 'inst1');
    expect(p.counterparty?.debtPath, '/personal-debts/people/i%3Ainst1');
    expect(p.plan?.count, 48);
    expect(p.plan?.next?.seq, 13);
    expect(p.plan?.next?.interest, 1813.5);
    expect(p.plan?.method, PlanInterestMethod.flat);
    expect(p.plan?.toMark?.seq, 13);
    expect(p.lines, hasLength(2));
    expect([for (final l in p.lines) l.seq], [1, 2]);
    expect(p.lines[0].autoAcceptOn, isTrue);
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

  test('a rule opens as a draft and goes back as its own input', () {
    final p = RecurringPage.fromJson(itemPageJson());
    final d = RuleDraft.fromLine(p.lines[1]);
    expect(d.type, RecurringKind.debt);
    expect(d.debtRecord, isTrue);
    final w = d.toJson();
    expect(w['id'], 'l2');
    expect((w['source'] as Map)['paid_by'], {
      'contact_id': 'c1',
      'person_name': 'แฟน',
    });
    expect(w['counterparty'], {'institution_id': 'inst1'});
    expect(w['notify'], isNull, reason: 'stored null = the user default');
  });
}
