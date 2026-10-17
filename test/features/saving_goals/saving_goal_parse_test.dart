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

/// The goal's auto-saving as the BE sends it (`SavingAutoSave`).
Map<String, dynamic> prodAutoSave({bool withWallet = true}) => {
  'amount': 5500,
  'day': 25,
  'wallet': withWallet ? wallet('w1', 'โดราเอมอน') : null,
  'next_date': '2026-10-25',
};

/// A goal as the BE sends it (0.4.0: month figures, status, auto_save).
Map<String, dynamic> prodGoal({
  String id = 'g1',
  String name = 'ทริปญี่ปุ่น',
  String state = 'active',
  String status = 'behind',
  int behindMonths = 2,
  num saved = 52000,
  num? monthShort = 2500,
  Map<String, dynamic>? autoSave,
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
  'auto_save': autoSave,
  'created_at': '2026-05-02T08:00:00Z',
  'updated_at': '2026-10-13T08:00:00Z',
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

/// The spare page (`GET /saving-goals/spare`): `auto_save` is an object here.
Map<String, dynamic> prodSpareDetail({Map<String, dynamic>? autoSave}) => {
  'spare': prodSpare(),
  'history': <dynamic>[],
  'auto_save': autoSave,
  'entries': prodEntries(const []),
};

Map<String, dynamic> prodList({List<Map<String, dynamic>>? goals}) => {
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
  },
  'spare': prodSpare(),
  'data': goals ?? [prodGoal()],
};

void main() {
  test(
    'a goal parses the 0.4.0 figures (BE computed, nothing client-side)',
    () {
      final g = SavingGoal.fromJson(prodGoal(autoSave: prodAutoSave()));
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
      expect(g.autoSave!.amount, 5500);
      expect(g.autoSave!.day, 25);
      expect(g.autoSave!.wallet!.name, 'โดราเอมอน');
      expect(g.autoSave!.nextDate, '2026-10-25');
      expect(g.milestones, hasLength(2));
      expect(g.actions.save, isTrue);
      expect(g.actions.delete, isFalse);
      expect(g.currency, 'THB');
    },
  );

  test('no auto-saving is null; a wallet-less one has no wallet', () {
    expect(SavingGoal.fromJson(prodGoal()).autoSave, isNull);
    final g = SavingGoal.fromJson(
      prodGoal(autoSave: prodAutoSave(withWallet: false)),
    );
    expect(g.autoSave!.wallet, isNull);
  });

  test('closed state and reached status; no plan = null month figures', () {
    final g = SavingGoal.fromJson(
      prodGoal(state: 'completed', status: 'reached', monthShort: null),
    );
    expect(g.isCompleted, isTrue);
    expect(g.status, SavingStatus.reached);
    expect(g.monthPlan, isNull);
    expect(g.monthShort, isNull);
  });

  test('the write body has no wallet and no %', () {
    final json = SavingGoal.fromJson(prodGoal()).toWriteJson();
    expect(json.keys, containsAll(['name', 'target_amount', 'deadline']));
    expect(json.keys, isNot(contains('linked_account_id')));
    expect(json.keys, isNot(contains('allocation_pct')));
    expect(json.keys, isNot(contains('auto_save')));
  });

  test('the goal page parses nested detail, entries and paging', () {
    final d = SavingGoalDetail.fromJson(
      prodDetail(goal: prodGoal(autoSave: prodAutoSave())),
    );
    expect(d.isSpare, isFalse);
    expect(d.goal!.name, 'ทริปญี่ปุ่น');
    expect(d.byWallet.map((w) => w.wallet!.name), ['กสิกร', 'ไทยพาณิชย์']);
    expect(d.history.last.cumulative, 52000);
    // The auto-saving lives on the goal now (no list on the page).
    expect(d.autoSave!.amount, 5500);
    expect(d.spareAutoSave, isNull);
    expect(d.entries.items.first.kind, SavingEntryKind.save);
    expect(d.entries.items.first.fromRecurring, isTrue);
    expect(d.entries.items.first.to.type, SavingEndpointType.goal);
    expect(d.entries.hasMore, isTrue);
  });

  test('an entry with no wallet parses (money saved outside the app)', () {
    final e = SavingEntry.fromJson(prodEntry(withWallet: false));
    expect(e.wallet, isNull);
    expect(e.from.type, SavingEndpointType.wallet);
  });

  test('a bucket share with no wallet parses', () {
    final s = SavingWalletShare.fromJson({
      'wallet': null,
      'amount': 1000,
      'share_pct': 10,
    });
    expect(s.wallet, isNull);
    expect(s.amount, 1000);
  });

  test('the spare page has no goal; its auto-saving is an object', () {
    final d = SavingGoalDetail.fromJson(
      prodSpareDetail(autoSave: prodAutoSave(withWallet: false)),
    );
    expect(d.isSpare, isTrue);
    expect(d.spare!.amount, 8500);
    expect(d.byWallet.single.wallet!.name, 'กสิกร');
    expect(d.spareAutoSave!.day, 25);
    expect(d.autoSave!.wallet, isNull);
    expect(SavingGoalDetail.fromJson(prodSpareDetail()).autoSave, isNull);
  });

  test('the list parses summary, spare and goals', () {
    final o = SavingGoalsOverview.fromJson(prodList());
    expect(o.summary.saved, 60500);
    expect(o.summary.savedTotal, 60500);
    expect(o.summary.monthShortTotal, 2500);
    expect(o.summary.unallocated, 8500);
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
  });

  test('a write answer carries the page it was made from', () {
    final r = SavingWriteResult.fromJson({
      'entries': <dynamic>[],
      'goals': <dynamic>[],
      'spare': prodSpare(),
      'wallets': <dynamic>[],
      'goal_page': prodDetail(),
      'spare_page': null,
    });
    expect(r.page!.goal!.name, 'ทริปญี่ปุ่น');
    expect(r.page!.entries.items, hasLength(2));
  });

  group('SavingPlanPreview (the edit form\'s live line)', () {
    final today = DateTime(2026, 10, 17);

    test('rounds the monthly need up to the baht', () {
      // 150 days ≈ 4.93 months → 5 months → 28,000 / 5 = 5,600.
      final p = SavingPlanPreview.of(
        target: 80000,
        saved: 52000,
        deadline: DateTime(2027, 3, 16),
        today: today,
      );
      expect(p.remaining, 28000);
      expect(p.neededMonthly, 5600);
    });

    test('no deadline, a past deadline or nothing left: no monthly need', () {
      expect(
        SavingPlanPreview.of(target: 100, saved: 0, today: today).neededMonthly,
        isNull,
      );
      expect(
        SavingPlanPreview.of(
          target: 100,
          saved: 0,
          deadline: DateTime(2026, 1, 1),
          today: today,
        ).neededMonthly,
        isNull,
      );
      final done = SavingPlanPreview.of(
        target: 100,
        saved: 150,
        deadline: DateTime(2027, 1, 1),
        today: today,
      );
      expect(done.remaining, 0);
      expect(done.neededMonthly, isNull);
    });
  });
}
