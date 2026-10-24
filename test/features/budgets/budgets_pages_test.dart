import 'dart:convert';

import 'package:chubi_pocket/core/data/data_changes.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/budgets/data/budgets_repository.dart';
import 'package:chubi_pocket/features/budgets/domain/budget.dart';
import 'package:chubi_pocket/features/budgets/domain/budget_detail.dart';
import 'package:chubi_pocket/features/budgets/domain/budget_period.dart';
import 'package:chubi_pocket/features/budgets/presentation/budget_draft.dart';
import 'package:chubi_pocket/features/budgets/presentation/budget_labels.dart';
import 'package:chubi_pocket/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

/// Records the request; answers with [body].
class _Adapter implements HttpClientAdapter {
  Object? body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Answers every list call with the prod-shaped body and records it.
class _ListRepo extends Fake implements BudgetsRepository {
  final calls = <String>[];

  @override
  Future<BudgetList> list({
    BudgetFilter filter = BudgetFilter.active,
    BudgetSort sort = BudgetSort.risk,
    BudgetHealth health = BudgetHealth.all,
  }) async {
    final h = health == BudgetHealth.all ? '' : ':${health.name}';
    calls.add('list:${filter.name}:${sort.name}$h');
    return BudgetList.fromJson(_list());
  }
}

Map<String, dynamic> _account() => {
  'id': 'a1',
  'name': 'KBank',
  'icon_code': null,
  'logo_url': null,
  'type': 'bank',
  'group': 'asset',
  'currency': 'THB',
  'archived': false,
};

Map<String, dynamic> _category() => {
  'id': 'c1',
  'name': 'Food',
  'type': 'expense',
  'icon_code': null,
  'is_system': false,
  'system_kind': null,
  'parent_id': null,
};

Map<String, dynamic> _period({
  String id = 'p1',
  int seq = 5,
  String start = '2026-10-01',
  String? end = '2026-10-31',
  bool current = true,
  double used = 3120,
  double expected = 900,
  double amount = 8000,
  String status = 'pace',
  String tone = 'neutral',
  bool overridden = false,
}) => {
  'id': id,
  'seq': seq,
  'start': start,
  'end': end,
  'amount': amount,
  'base_amount': 8000,
  'overridden': overridden,
  'note': null,
  'is_current': current,
  'used': used,
  'expected': expected,
  'remaining': amount - used,
  'over_by': used > amount ? used - amount : 0,
  'pct': (used / amount * 100).round(),
  'status': status,
  'tone': tone,
  'days_left': current ? 24 : null,
  'on_pace_to_exceed': status == 'pace',
};

/// A budget as `listBudgets` / `getBudget` send it.
Map<String, dynamic> _budget({
  String id = 'b1',
  String name = 'อาหาร',
  bool recurring = true,
  Map<String, dynamic>? period,
  Map<String, dynamic> end = const {
    'kind': 'none',
    'date': null,
    'count': null,
  },
  String state = 'active',
  Map<String, dynamic>? actions,
}) => {
  'id': id,
  'name': name,
  'description': 'กินนอกบ้าน',
  'note': null,
  'icon_code': null,
  'amount': 8000,
  'warn_pct': 80,
  'scope': {
    'all': false,
    'categories': [
      {'category': _category(), 'include_children': true},
    ],
    'tags': ['เที่ยว'],
    'wallets': [_account()],
  },
  'recurring': recurring,
  'rule': recurring ? {'freq': 'monthly', 'interval': 1} : null,
  'start_date': '2026-05-01',
  'end': end,
  'state': state,
  'closed_on': null,
  'period': period ?? _period(),
  'actions':
      actions ??
      {'edit': true, 'close': !recurring, 'archive': true, 'restore': false},
  'created_at': '2026-05-01T08:00:00Z',
  'updated_at': '2026-10-01T08:00:00Z',
};

Map<String, dynamic> _list() => {
  'summary': {
    'active_count': 2,
    'over_count': 1,
    'warn_count': 0,
    'pace_count': 1,
    'ended_count': 3,
    'archived_count': 0,
    'total_limit': 12000,
    'total_used': 7980,
    'total_remaining': 4020,
    'used_pct': 67,
    'counts': {'all': 2, 'ok': 1, 'near': 0, 'over': 1},
  },
  'data': [
    _budget(
      id: 'b2',
      name: 'ช้อปปิ้ง',
      period: _period(
        id: 'p9',
        used: 4860,
        amount: 4000,
        expected: 0,
        status: 'over',
        tone: 'danger',
      ),
    ),
    _budget(),
  ],
};

Map<String, dynamic> _item({
  String source = 'normal',
  String countsAs = 'used',
  String kind = 'transaction',
  String reason = 'category',
  String description = 'ข้าวมันไก่',
  String date = '2026-10-08',
  Map<String, dynamic>? category,
  List<String> tags = const [],
}) => {
  'kind': kind,
  'id': 'i-$description',
  'source': source,
  'counts_as': countsAs,
  'date': date,
  'amount': 60,
  'description': description,
  'category': category ?? _category(),
  'account': _account(),
  'tags': tags,
  'event': null,
  'recurring': null,
  'reason': reason,
};

Map<String, dynamic> _recurringDetail() => {
  'budget': _budget(),
  'forecast': {
    'elapsed_days': 8,
    'total_days': 31,
    'daily_allowance': 165,
    'avg_daily': 390,
    'avg_monthly': null,
    'forecast_end': 12990,
    'forecast_over_by': 4990,
    'forecast_over_date': '2026-10-19',
    'remaining_after_expected': 3980,
    'this_month': null,
    'history_avg': 7530,
    'history_count': 6,
    'available': 4880,
    'projected_end': 12990,
    'days_left': 24,
    'pace_pct': 26,
  },
  'by_source': [
    {'source': 'normal', 'counts_as': 'used', 'count': 18, 'amount': 2460},
    {'source': 'event', 'counts_as': 'used', 'count': 2, 'amount': 660},
    {'source': 'upcoming', 'counts_as': 'expected', 'count': 1, 'amount': 450},
    {'source': 'pending', 'counts_as': 'expected', 'count': 2, 'amount': 270},
  ],
  'by_category': [
    {'category': _category(), 'amount': 3120, 'pct': 100},
  ],
  'periods': {
    'data': [
      _period(),
      _period(
        id: 'p0',
        seq: 4,
        start: '2026-09-01',
        end: '2026-09-30',
        current: false,
        used: 8460,
        expected: 0,
        status: 'over',
        tone: 'danger',
      ),
    ],
    'has_more': true,
  },
  'items': {
    'data': [
      _item(
        source: 'upcoming',
        countsAs: 'expected',
        kind: 'recurring_item',
        description: 'ค่าเน็ต',
        date: '2026-10-20',
        reason: 'wallet',
      ),
      _item(),
      _item(
        description: 'ก๋วยเตี๋ยว',
        reason: 'sub_category',
        category: {
          ..._category(),
          'id': 'c2',
          'name': 'Noodles',
          'parent_id': 'c1',
        },
      ),
      _item(
        description: 'ตั๋วรถ',
        reason: 'tag',
        date: '2026-10-07',
        tags: ['เที่ยว'],
      ),
    ],
    'pagination': {'page': 1, 'per_page': 20, 'total': 4, 'total_pages': 1},
  },
};

Map<String, dynamic> _openEndedDetail() => {
  ..._recurringDetail(),
  'budget': _budget(
    id: 'b3',
    name: 'รีโนเวท',
    recurring: false,
    period: _period(
      id: 'p7',
      start: '2026-08-01',
      end: null,
      used: 64300,
      amount: 100000,
      expected: 8500,
      status: 'ok',
    ),
  ),
  'periods': {'data': <dynamic>[], 'has_more': false},
};

void main() {
  group('model', () {
    test('a budget list parses the BE statuses and the summary', () {
      final l = BudgetList.fromJson(_list());
      expect(l.summary.activeCount, 2);
      expect(l.summary.overCount, 1);
      expect(l.budgets.first.period.status, BudgetStatus.over);
      expect(l.budgets.first.period.tone, BudgetTone.danger);
      expect(l.budgets.first.period.overBy, 860);
      expect(l.budgets.last.recurring, isTrue);
      expect(l.budgets.last.rule?.freq, 'monthly');
      expect(l.budgets.last.scope.tags, ['เที่ยว']);
      expect(l.budgets.last.scope.categories.single.includeChildren, isTrue);
      expect(l.summary.totalLimit, 12000);
      expect(l.summary.totalUsed, 7980);
      expect(l.summary.totalRemaining, 4020);
      expect(l.summary.usedPct, 67);
      expect(l.summary.countAll, 2);
      expect(l.summary.countOk, 1);
      expect(l.summary.countOver, 1);
      expect(l.budgets.last.period.onPaceToExceed, isTrue);
    });

    test('the pace tick: elapsed fraction of the period, null when open', () {
      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 31);
      expect(budgetPaceFraction(start, end, DateTime(2026, 10, 16)), 0.5);
      expect(budgetPaceFraction(start, end, DateTime(2026, 9, 1)), 0);
      expect(budgetPaceFraction(start, end, DateTime(2026, 12, 1)), 1);
      expect(budgetPaceFraction(start, null, DateTime(2026, 10, 16)), isNull);
      expect(budgetPaceFraction(start, start, DateTime(2026, 10, 1)), isNull);
    });

    test('the detail parses forecast, sources, periods and items', () {
      final d = BudgetDetail.fromJson(_recurringDetail());
      expect(d.forecast.dailyAllowance, 165);
      expect(d.forecast.forecastOverDate, DateTime(2026, 10, 19));
      expect(d.bySource.map((s) => s.source), [
        BudgetSource.normal,
        BudgetSource.event,
        BudgetSource.upcoming,
        BudgetSource.pending,
      ]);
      expect(d.bySource.where((s) => s.expected).length, 2);
      expect(d.periods.hasMore, isTrue);
      expect(d.items.items.first.expected, isTrue);
      // The 0.4.0 forecast numbers and each row's reason.
      expect(d.forecast.available, 4880);
      expect(d.forecast.projectedEnd, 12990);
      expect(d.forecast.daysLeft, 24);
      expect(d.forecast.pacePct, 26);
      expect(d.items.items.map((i) => i.reason), [
        BudgetReason.wallet,
        BudgetReason.category,
        BudgetReason.subCategory,
        BudgetReason.tag,
      ]);
    });

    test('a period write answers at that period: only an old one patches', () {
      final d = BudgetDetail.fromJson(_recurringDetail());
      Map<String, dynamic> at(String id, double amount) => {
        ..._recurringDetail(),
        'budget': _budget(
          period: _period(
            id: id,
            amount: amount,
            overridden: true,
            current: id == 'p1',
          ),
        ),
      };
      final old = d.afterPeriodWrite(BudgetDetail.fromJson(at('p0', 9000)));
      expect(old.budget.period.id, 'p1');
      expect(old.periods.periods.last.amount, 9000);
      expect(old.periods.periods.first.amount, 8000);
      final cur = d.afterPeriodWrite(BudgetDetail.fromJson(at('p1', 7000)));
      expect(cur.budget.period.amount, 7000);
    });

    test('an open-ended budget has no period end', () {
      final d = BudgetDetail.fromJson(_openEndedDetail());
      expect(d.budget.openEnded, isTrue);
      expect(d.budget.period.end, isNull);
      expect(d.budget.actions.close, isTrue);
    });

    test('the setup draft round-trips to the write body', () {
      final b = Budget.fromJson(_budget());
      final json = BudgetDraft.from(b).toWrite().toJson(apply: 'all');
      expect(json['name'], 'อาหาร');
      expect(json['amount'], 8000);
      expect(json['warn_pct'], 80);
      expect(json['recurring'], isTrue);
      expect(json['rule'], {'freq': 'monthly', 'interval': 1});
      expect(json['start_date'], '2026-05-01');
      expect(json['end'], {'kind': 'none'});
      expect(json['apply'], 'all');
      final scope = json['scope'] as Map<String, dynamic>;
      expect(scope['all'], isFalse);
      expect(scope['tags'], ['เที่ยว']);
      expect(scope['wallet_ids'], ['a1']);
      expect(scope['categories'], [
        {'id': 'c1', 'include_children': true},
      ]);
      // no currency anywhere
      expect(json.containsKey('currency'), isFalse);
    });

    test(
      'a one-off keeps no rule and an "everything" scope sends no lists',
      () {
        final d = BudgetDraft.blank().copyWith(
          name: 'ทริป',
          amount: '5,000',
          recurring: false,
          allScope: true,
          end: BudgetEnd.onDate(DateTime(2026, 10, 10)),
        );
        final json = d.toWrite().toJson();
        expect(json.containsKey('rule'), isFalse);
        expect(json['end'], {'kind': 'date', 'date': '2026-10-10'});
        final scope = json['scope'] as Map<String, dynamic>;
        expect(scope['all'], isTrue);
        expect(scope['categories'], isEmpty);
        expect(d.scopeEmpty, isFalse);
        expect(BudgetDraft.blank().scopeEmpty, isTrue);
      },
    );

    test('a period change asks "which periods", a text change does not', () {
      final b = BudgetDraft.from(Budget.fromJson(_budget()));
      expect(b.periodShapeDiffers(b.copyWith(note: 'x', name: 'y')), isFalse);
      expect(b.periodShapeDiffers(b.copyWith(amount: '9,000')), isTrue);
      expect(b.periodShapeDiffers(b.copyWith(interval: 2)), isTrue);
    });
  });

  test('repository writes: period limit, override reset, archive, preview', () async {
    final http = _Adapter();
    final repo = BudgetsRepository(
      client: _FakeApi(Dio()..httpClientAdapter = http),
    );
    final cases =
        <
          ({
            String name,
            Future<Object?> Function() call,
            Object body,
            String method,
            String path,
            Map<String, dynamic> query,
            Object? data,
          })
        >[
          (
            name: 'period limit: one PUT with the amount',
            call: () =>
                repo.updatePeriod('b1', 'p0', amount: 9000, note: null),
            body: _recurringDetail(),
            method: 'PUT',
            path: '/budgets/b1/periods/p0',
            query: {},
            data: {'amount': 9000, 'note': null},
          ),
          (
            name: 'override reset: amount null goes back to the base',
            call: () => repo.updatePeriod('b1', 'p0', amount: null, note: 'n'),
            body: _recurringDetail(),
            method: 'PUT',
            path: '/budgets/b1/periods/p0',
            query: {},
            data: {'amount': null, 'note': 'n'},
          ),
          (
            name: 'archive',
            call: () => repo.archive('b1'),
            body: _recurringDetail(),
            method: 'POST',
            path: '/budgets/b1/archive',
            query: {},
            data: null,
          ),
          (
            name: 'restore',
            call: () => repo.restore('b1'),
            body: _recurringDetail(),
            method: 'POST',
            path: '/budgets/b1/restore',
            query: {},
            data: null,
          ),
          (
            name: 'delete',
            call: () => repo.delete('b1'),
            body: <String, dynamic>{},
            method: 'DELETE',
            path: '/budgets/b1',
            query: {},
            data: null,
          ),
          (
            name: 'delete preview',
            call: () => repo.get('b1', deletePreview: true),
            body: _recurringDetail(),
            method: 'GET',
            path: '/budgets/b1',
            query: {'include': 'delete_preview'},
            data: null,
          ),
          (
            name: 'detail at a period',
            call: () => repo.get('b1', periodId: 'p0'),
            body: _recurringDetail(),
            method: 'GET',
            path: '/budgets/b1',
            query: {'period_id': 'p0'},
            data: null,
          ),
          (
            name: 'list with a health tile',
            call: () => repo.list(health: BudgetHealth.over),
            body: _list(),
            method: 'GET',
            path: '/budgets',
            query: {'status': 'active', 'sort': 'risk', 'health': 'over'},
            data: null,
          ),
          (
            name: 'list without a health tile sends no health',
            call: () => repo.list(filter: BudgetFilter.ended),
            body: _list(),
            method: 'GET',
            path: '/budgets',
            query: {'status': 'ended', 'sort': 'risk'},
            data: null,
          ),
        ];

    for (final c in cases) {
      http.body = c.body;
      await c.call();
      final sent = http.last!;
      expect(sent.method, c.method, reason: c.name);
      expect(sent.path, c.path, reason: c.name);
      expect(sent.queryParameters, c.query, reason: c.name);
      expect(sent.data, c.data, reason: c.name);
    }
  });

  test('cubit: a budgets change refreshes it once loaded; one call per '
      'filter, sort or tile change', () async {
    final repo = _ListRepo();
    final cubit = BudgetsCubit(repository: repo);
    addTearDown(cubit.close);

    await DataChanges.instance.changed({DataTable.budgets});
    expect(repo.calls, isEmpty);

    await cubit.load();
    expect(repo.calls, ['list:active:risk']);

    await DataChanges.instance.changed({DataTable.budgets});
    expect(repo.calls.length, 2);
    await DataChanges.instance.changed({DataTable.accounts});
    expect(repo.calls.length, 2);

    repo.calls.clear();
    await cubit.setHealth(BudgetHealth.over);
    await cubit.setHealth(BudgetHealth.over);
    await cubit.setFilter(BudgetFilter.ended);
    await cubit.setFilter(BudgetFilter.ended);
    await cubit.setSort(BudgetSort.newest);
    expect(repo.calls, [
      'list:active:risk:over',
      'list:active:risk',
      'list:ended:risk',
      'list:ended:newest',
    ]);
  });
}
