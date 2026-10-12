import 'package:chubi_pocket/features/saving_goals/domain/saving_entry.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goal.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goals_overview.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> wallet(String id, String name) => {
  'id': id,
  'name': name,
  'icon_code': null,
  'logo_url': null,
  'type': 'bank',
  'group': 'asset',
  'currency': 'THB',
  'archived': false,
};

/// A goal as the BE sends it (goals v2 spec).
Map<String, dynamic> prodGoal({
  String state = 'active',
  String pace = 'late',
}) => {
  'id': 'g1',
  'name': 'ทริปญี่ปุ่น',
  'description': 'เที่ยวโตเกียว',
  'note': null,
  'icon_code': null,
  'target_amount': 80000,
  'deadline': '2027-03-15',
  'state': state,
  'saved_amount': 52000,
  'progress_pct': 65,
  'remaining_amount': 28000,
  'days_remaining': 153,
  'needed_monthly': 5600,
  'pace_monthly': 4000,
  'eta_date': '2027-05-13',
  'pace': pace,
  'late_months': 2,
  'milestones': [
    {'pct': 25, 'amount': 20000, 'reached': true},
    {'pct': 100, 'amount': 80000, 'reached': false},
  ],
  'currency': 'THB',
  'closed_at': null,
  'actions': {
    'save': true,
    'withdraw': true,
    'move': true,
    'close': true,
    'archive': false,
    'restore': false,
    'delete': false,
  },
  'created_at': '2026-05-02T08:00:00Z',
  'updated_at': '2026-10-13T08:00:00Z',
};

Map<String, dynamic> prodEntry() => {
  'id': 'e1',
  'group_id': 'grp1',
  'kind': 'save',
  'date': '2026-10-13',
  'note': null,
  'wallet': wallet('w1', 'กสิกร'),
  'amount': 4000,
  'from': {'type': 'wallet', 'id': 'w1', 'name': 'กสิกร', 'icon_code': null},
  'to': {'type': 'goal', 'id': 'g1', 'name': 'ทริปญี่ปุ่น', 'icon_code': null},
  'source': 'recurring',
  'goal_ids': ['g1'],
  'recurring': null,
  'created_at': '2026-10-13T08:00:00Z',
};

Map<String, dynamic> prodDetail() => {
  'goal': prodGoal(),
  'by_wallet': [
    {'wallet': wallet('w1', 'กสิกร'), 'amount': 40000, 'share_pct': 77},
    {'wallet': wallet('w2', 'ไทยพาณิชย์'), 'amount': 12000, 'share_pct': 23},
  ],
  'history': [
    {'month': '2026-09', 'cumulative': 48000},
    {'month': '2026-10', 'cumulative': 52000},
  ],
  'auto_save': [
    {
      'recurring': {'id': 'r1', 'name': 'ออมทริป', 'icon_code': null},
      'amount': 4000,
      'rule': {},
      'next_date': '2026-10-25',
    },
  ],
  'entries': {
    'data': [prodEntry()],
    'pagination': {'page': 1, 'per_page': 20, 'total': 45, 'total_pages': 3},
  },
};

Map<String, dynamic> prodList() => {
  'summary': {
    'saved': 216500,
    'in_goals': 208000,
    'spare': 8500,
    'currency': 'THB',
  },
  'spare': {
    'amount': 8500,
    'by_wallet': [
      {'wallet': wallet('w1', 'กสิกร'), 'amount': 8500, 'share_pct': 100},
    ],
  },
  'data': [prodGoal()],
};

void main() {
  test('a goal parses the v2 figures (BE computed, nothing client-side)', () {
    final g = SavingGoal.fromJson(prodGoal());
    expect(g.state, SavingGoalState.active);
    expect(g.savedAmount, 52000);
    expect(g.progressPct, 65);
    expect(g.neededMonthly, 5600);
    expect(g.paceMonthly, 4000);
    expect(g.pace, SavingPace.late);
    expect(g.lateMonths, 2);
    expect(g.milestones, hasLength(2));
    expect(g.milestones.first.reached, isTrue);
    expect(g.actions.save, isTrue);
    expect(g.actions.delete, isFalse);
    expect(g.currency, 'THB');
  });

  test('closed state and reached pace', () {
    final g = SavingGoal.fromJson(
      prodGoal(state: 'completed', pace: 'reached'),
    );
    expect(g.isCompleted, isTrue);
    expect(g.pace, SavingPace.reached);
  });

  test('the write body has no wallet and no %', () {
    final json = SavingGoal.fromJson(prodGoal()).toWriteJson();
    expect(json.keys, containsAll(['name', 'target_amount', 'deadline']));
    expect(json.keys, isNot(contains('linked_account_id')));
    expect(json.keys, isNot(contains('allocation_pct')));
  });

  test('the goal page parses nested detail, entries and paging', () {
    final d = SavingGoalDetail.fromJson(prodDetail());
    expect(d.isSpare, isFalse);
    expect(d.goal!.name, 'ทริปญี่ปุ่น');
    expect(d.byWallet.map((w) => w.wallet.name), ['กสิกร', 'ไทยพาณิชย์']);
    expect(d.history.last.cumulative, 52000);
    expect(d.autoSave.single.name, 'ออมทริป');
    expect(d.entries.items.single.kind, SavingEntryKind.save);
    expect(d.entries.items.single.fromRecurring, isTrue);
    expect(d.entries.items.single.to.type, SavingEndpointType.goal);
    expect(d.entries.hasMore, isTrue);
  });

  test('the spare page has no goal', () {
    final d = SavingGoalDetail.fromJson({
      'spare': prodList()['spare'],
      'history': <dynamic>[],
      'auto_save': <dynamic>[],
      'entries': {
        'data': <dynamic>[],
        'pagination': {'page': 1, 'per_page': 20, 'total': 0, 'total_pages': 1},
      },
    });
    expect(d.isSpare, isTrue);
    expect(d.spare!.amount, 8500);
    expect(d.byWallet.single.wallet.name, 'กสิกร');
  });

  test('the list parses summary, spare and goals', () {
    final o = SavingGoalsOverview.fromJson(prodList());
    expect(o.summary.saved, 216500);
    expect(o.spare.amount, 8500);
    expect(o.goals, hasLength(1));
  });

  test('a write answer carries every touched goal', () {
    final r = SavingWriteResult.fromJson({
      'entries': [prodEntry()],
      'goals': [prodGoal()],
      'spare': prodList()['spare'],
      'wallets': <dynamic>[],
    });
    expect(r.goalById('g1')!.savedAmount, 52000);
    expect(r.goalById('nope'), isNull);
    expect(r.spare.amount, 8500);
    expect(r.page, isNull);
  });

  test('a write answer carries the page it was made from', () {
    final r = SavingWriteResult.fromJson({
      'entries': <dynamic>[],
      'goals': <dynamic>[],
      'spare': prodList()['spare'],
      'wallets': <dynamic>[],
      'goal_page': prodDetail(),
      'spare_page': null,
    });
    expect(r.page!.goal!.name, 'ทริปญี่ปุ่น');
    expect(r.page!.entries.items, hasLength(1));
  });
}
