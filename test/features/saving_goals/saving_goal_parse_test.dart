import 'package:chubi_pocket/features/saving_goals/domain/saving_entry.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goal.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goals_overview.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_plan_preview.dart';
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

/// A goal as the BE sends it (0.4.0: month figures, status).
Map<String, dynamic> prodGoal({
  String id = 'g1',
  String name = 'ทริปญี่ปุ่น',
  String state = 'active',
  String status = 'behind',
  int behindMonths = 2,
  num saved = 52000,
  num? monthShort = 2500,
  Map<String, bool> actions = const {},
}) => {
  'id': id,
  'name': name,
  'description': 'เที่ยวโตเกียว',
  'note': null,
  'icon_code': null,
  'target_amount': 80000,
  'deadline': '2027-03-15',
  'state': state,
  'saved_amount': saved,
  'progress_pct': 65,
  'remaining_amount': 28000,
  'days_remaining': 153,
  'needed_monthly': 5600,
  'pace_monthly': 4000,
  'eta_date': '2027-05-13',
  'pace': 'late',
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
    ...actions,
  },
  'month_plan': monthShort == null ? null : 5500,
  'month_saved': 3000,
  'month_short': monthShort,
  'status': status,
  'behind_months': status == 'behind' ? behindMonths : null,
  'created_at': '2026-05-02T08:00:00Z',
  'updated_at': '2026-10-13T08:00:00Z',
};

/// A goal with no target (ออมต่อเนื่อง, 0.4.0-1) as the BE sends it: no %,
/// remaining, milestones, ETA or month_short; status none; group ongoing.
Map<String, dynamic> prodOngoingGoal({
  String id = 'g9',
  String name = 'เงินเก็บให้ลูก',
  num saved = 45000,
}) => {
  ...prodGoal(id: id, name: name, saved: saved),
  'description': 'เก็บไว้ให้น้องโต',
  'target_amount': null,
  'deadline': null,
  'progress_pct': null,
  'remaining_amount': null,
  'days_remaining': null,
  'needed_monthly': null,
  'pace_monthly': null,
  'eta_date': null,
  'pace': 'none',
  'late_months': null,
  'milestones': <dynamic>[],
  'month_plan': null,
  'month_saved': 2000,
  'month_short': null,
  'status': 'none',
  'behind_months': null,
  'group': 'ongoing',
};

Map<String, dynamic> prodEntry({
  String id = 'e1',
  bool withWallet = true,
  String source = 'recurring',
}) => {
  'id': id,
  'group_id': 'grp-$id',
  'kind': 'save',
  'date': '2026-10-13',
  'note': null,
  'wallet': withWallet ? wallet('w1', 'กสิกร') : null,
  'amount': 4000,
  'from': {
    'type': 'wallet',
    'id': withWallet ? 'w1' : null,
    'name': withWallet ? 'กสิกร' : null,
    'icon_code': null,
  },
  'to': {'type': 'goal', 'id': 'g1', 'name': 'ทริปญี่ปุ่น', 'icon_code': null},
  'source': source,
  'goal_ids': ['g1'],
  'recurring': null,
  'created_at': '2026-10-13T08:00:00Z',
};

Map<String, dynamic> prodEntries(List<Map<String, dynamic>> data) => {
  'data': data,
  'pagination': {'page': 1, 'per_page': 20, 'total': 45, 'total_pages': 3},
};

Map<String, dynamic> prodDetail({
  Map<String, dynamic>? goal,
  List<Map<String, dynamic>>? entries,
}) => {
  'goal': goal ?? prodGoal(),
  'by_wallet': [
    {'wallet': wallet('w1', 'กสิกร'), 'amount': 40000, 'share_pct': 77},
    {'wallet': wallet('w2', 'ไทยพาณิชย์'), 'amount': 12000, 'share_pct': 23},
  ],
  'history': [
    {'month': '2026-09', 'cumulative': 48000, 'plan': 45000},
    {'month': '2026-10', 'cumulative': 52000, 'plan': 50500},
  ],
  'entries': prodEntries(entries ?? [prodEntry(), prodEntry(id: 'e2')]),
  'delete_preview': null,
};

Map<String, dynamic> prodSpare() => {
  'amount': 8500,
  'by_wallet': [
    {'wallet': wallet('w1', 'กสิกร'), 'amount': 8500, 'share_pct': 100},
  ],
};

/// The spare page (`GET /saving-goals/spare`).
Map<String, dynamic> prodSpareDetail() => {
  'spare': prodSpare(),
  'history': <dynamic>[],
  'entries': prodEntries(const []),
};

/// [summary] overrides the summary's keys (e.g. the long-term counts).
Map<String, dynamic> prodList({
  List<Map<String, dynamic>>? goals,
  Map<String, dynamic> summary = const {},
}) => {
  'summary': {
    'saved': 60500,
    'in_goals': 52000,
    'spare': 8500,
    'currency': 'THB',
    'saved_total': 60500,
    'month_short_total': 2500,
    'month_plan_total': 5500,
    'month_saved_total': 3000,
    'unallocated': 8500,
    // Long-term (0.4.0-3; names as proposed to the BE).
    'target_total': 80000,
    'target_saved_total': 52000,
    'target_short_total': 28000,
    'target_percent': 65,
    'count_short': 1,
    'count_done': 0,
    'count_no_target': 0,
    ...summary,
  },
  'spare': prodSpare(),
  'data': goals ?? [prodGoal()],
};

void main() {
  test(
    'a goal parses the 0.4.0 figures (BE computed, nothing client-side)',
    () {
      final g = SavingGoal.fromJson(prodGoal());
      expect(g.state, SavingGoalState.active);
      expect(g.savedAmount, 52000);
      expect(g.progressPct, 65);
      expect(g.neededMonthly, 5600);
      expect(g.paceMonthly, 4000);
      expect(g.status, SavingStatus.behind);
      expect(g.behindMonths, 2);
      expect(g.monthPlan, 5500);
      expect(g.monthSaved, 3000);
      expect(g.monthShort, 2500);
      expect(g.milestones, hasLength(2));
      expect(g.actions.save, isTrue);
      expect(g.actions.delete, isFalse);
      expect(g.currency, 'THB');
    },
  );

  test('closed state and reached status; no plan = null month figures', () {
    final g = SavingGoal.fromJson(
      prodGoal(state: 'completed', status: 'reached', monthShort: null),
    );
    expect(g.isCompleted, isTrue);
    expect(g.status, SavingStatus.reached);
    expect(g.monthPlan, isNull);
    expect(g.monthShort, isNull);
  });

  test('a goal with no target parses as ongoing (0.4.0-1)', () {
    final g = SavingGoal.fromJson(prodOngoingGoal());
    expect(g.isOngoing, isTrue);
    expect(g.group, 'ongoing');
    expect(g.targetAmount, isNull);
    expect(g.progressPct, isNull);
    expect(g.remainingAmount, isNull);
    expect(g.monthShort, isNull);
    expect(g.status, SavingStatus.none);
    expect(SavingGoal.fromJson(prodGoal()).isOngoing, isFalse);
  });

  test('the write body', () {
    final ongoing = SavingGoal.fromJson(prodOngoingGoal()).toWriteJson();
    expect(
      ongoing.containsKey('target_amount'),
      isTrue,
      reason: 'no target writes null (clears it on update)',
    );
    expect(ongoing['target_amount'], isNull);
    expect(ongoing['deadline'], isNull);
    final json = SavingGoal.fromJson(prodGoal()).toWriteJson();
    expect(json['target_amount'], 80000);
    expect(json['deadline'], '2027-03-15');
    expect(json.keys, containsAll(['name', 'target_amount', 'deadline']));
    for (final key in ['linked_account_id', 'allocation_pct', 'auto_save']) {
      expect(json.keys, isNot(contains(key)), reason: key);
    }
  });

  test('the goal page parses nested detail, entries and paging', () {
    final d = SavingGoalDetail.fromJson(prodDetail());
    expect(d.isSpare, isFalse);
    expect(d.goal!.name, 'ทริปญี่ปุ่น');
    expect(d.byWallet.map((w) => w.wallet!.name), ['กสิกร', 'ไทยพาณิชย์']);
    expect(d.history.last.cumulative, 52000);
    expect(d.entries.items.first.kind, SavingEntryKind.save);
    expect(d.entries.items.first.fromRecurring, isTrue);
    expect(d.entries.items.first.to.type, SavingEndpointType.goal);
    expect(d.entries.hasMore, isTrue);
    expect(d.deletePreview, isNull);
  });

  test('the delete preview: money held blocks, a missing flag blocks', () {
    for (final c in <({String name, dynamic preview, bool? can, int entries})>[
      (
        name: 'money held',
        preview: {'entries': 4, 'saved_amount': 52000, 'can_delete': false},
        can: false,
        entries: 4,
      ),
      (
        name: 'empty goal',
        preview: {'entries': 4, 'saved_amount': 0, 'can_delete': true},
        can: true,
        entries: 4,
      ),
      (name: 'no flag', preview: <String, dynamic>{}, can: false, entries: 0),
      (name: 'no preview', preview: null, can: null, entries: 0),
    ]) {
      final p = SavingGoalDetail.fromJson({
        ...prodDetail(),
        'delete_preview': c.preview,
      }).deletePreview;
      expect(p?.canDelete, c.can, reason: c.name);
      expect(p?.entries ?? 0, c.entries, reason: c.name);
    }
  });

  test('no-wallet shapes parse (money saved outside the app)', () {
    final e = SavingEntry.fromJson(prodEntry(withWallet: false));
    expect(e.wallet, isNull);
    expect(e.from.type, SavingEndpointType.wallet);
    final s = SavingWalletShare.fromJson({
      'wallet': null,
      'amount': 1000,
      'share_pct': 10,
    });
    expect(s.wallet, isNull);
    expect(s.amount, 1000);
  });

  test('the spare page has no goal', () {
    final d = SavingGoalDetail.fromJson(prodSpareDetail());
    expect(d.isSpare, isTrue);
    expect(d.spare!.amount, 8500);
    expect(d.byWallet.single.wallet!.name, 'กสิกร');
  });

  test('the list parses summary, spare and goals', () {
    final o = SavingGoalsOverview.fromJson(prodList());
    expect(o.summary.saved, 60500);
    expect(o.summary.savedTotal, 60500);
    expect(o.summary.monthShortTotal, 2500);
    expect(o.summary.unallocated, 8500);
    // Long-term progress + the filter counts (0.4.0-3).
    expect(o.summary.targetTotal, 80000);
    expect(o.summary.targetSavedTotal, 52000);
    expect(o.summary.targetShortTotal, 28000);
    expect(o.summary.targetPercent, 65);
    expect(o.summary.countShort, 1);
    expect(o.summary.countDone, 0);
    expect(o.summary.countNoTarget, 0);
    expect(o.spare.amount, 8500);
    expect(o.goals, hasLength(1));
  });

  test('a write answer carries every touched goal', () {
    final r = SavingWriteResult.fromJson({
      'entries': [prodEntry()],
      'goals': [prodGoal()],
      'spare': prodSpare(),
      'wallets': <dynamic>[],
    });
    expect(r.goalById('g1')!.savedAmount, 52000);
    expect(r.goalById('nope'), isNull);
    expect(r.spare.amount, 8500);
    expect(r.page, isNull);
    final paged = SavingWriteResult.fromJson({
      'entries': <dynamic>[],
      'goals': <dynamic>[],
      'spare': prodSpare(),
      'wallets': <dynamic>[],
      'goal_page': prodDetail(),
      'spare_page': null,
    });
    expect(paged.page!.goal!.name, 'ทริปญี่ปุ่น');
    expect(paged.page!.entries.items, hasLength(2));
  });

  test('SavingPlanPreview (the edit form\'s live line)', () {
    final today = DateTime(2026, 10, 17);
    // 150 days ≈ 4.93 months → 5 months → 28,000 / 5 = 5,600.
    final p = SavingPlanPreview.of(
      target: 80000,
      saved: 52000,
      deadline: DateTime(2027, 3, 16),
      today: today,
    );
    expect(p.remaining, 28000);
    expect(p.neededMonthly, 5600);
    expect(
      SavingPlanPreview.of(target: 100, saved: 0, today: today).neededMonthly,
      isNull,
      reason: 'no deadline',
    );
    expect(
      SavingPlanPreview.of(
        target: 100,
        saved: 0,
        deadline: DateTime(2026, 1, 1),
        today: today,
      ).neededMonthly,
      isNull,
      reason: 'past deadline',
    );
    final done = SavingPlanPreview.of(
      target: 100,
      saved: 150,
      deadline: DateTime(2027, 1, 1),
      today: today,
    );
    expect(done.remaining, 0);
    expect(done.neededMonthly, isNull, reason: 'nothing left');
  });
}
