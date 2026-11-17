import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/recurrence_rule.dart' show parseYmd, ymd;
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';
import '../domain/recurring_page.dart';

class RecurringRepository {
  RecurringRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  static RecurringRepository of(BuildContext context) =>
      context.read<RecurringRepository>();

  Future<T> _call<T>(Future<T> Function(Dio dio) run) async {
    try {
      return await run(_client.dio);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  /// The item page and its first rounds (past / ahead), in parallel.
  Future<RecurringDetail> get(String id) => _call((dio) async {
    final page = dio.get<Map<String, dynamic>>('/recurring/$id');
    final produced = items(id, upcoming: false);
    final upcoming = items(id, upcoming: true);
    return RecurringDetail.fromPage(
      RecurringPage.fromJson((await page).data!),
      produced: await produced,
      upcoming: await upcoming,
    );
  });

  /// After a write: the item page it answered with, and its rounds again
  /// (a write may move them).
  Future<RecurringDetail> _withRounds(Map<String, dynamic> body) async {
    final page = RecurringPage.fromJson(body);
    final produced = items(page.id, upcoming: false);
    final upcoming = items(page.id, upcoming: true);
    return RecurringDetail.fromPage(
      page,
      produced: await produced,
      upcoming: await upcoming,
    );
  }

  Future<RecurringDetail> _write(
    Future<Response<Map<String, dynamic>>> Function(Dio dio) send,
  ) => _call((dio) async => _withRounds((await send(dio)).data!));

  Future<RecurringDetail> create(RecurringWrite write) =>
      _write((dio) => dio.post('/recurring', data: write.toJson()));

  Future<RecurringDetail> update(String id, RecurringWrite write) =>
      _write((dio) => dio.put('/recurring/$id', data: write.toJson()));

  Future<RecurringDetail> duplicate(String id) =>
      _write((dio) => dio.post('/recurring/$id/duplicate'));

  /// Deletes the item and its lines; what its rounds wrote stays (txs as
  /// they are, debt rows become general debts).
  Future<Map<String, double>> delete(String id) => _call((dio) async {
    final res = await dio.delete<Map<String, dynamic>>('/recurring/$id');
    return ItemWriteResult.fromJson(res.data ?? const {}).balances;
  });

  Future<RecurringDetail> action(String id, RecurringAction action) =>
      _write((dio) => dio.post('/recurring/$id/${action.name}'));

  /// Extends a line (its own end; [lineId] null = the item's first line,
  /// which a one-line item shares the id of).
  Future<RecurringDetail> extend(
    String id, {
    String? lineId,
    Map<String, dynamic>? end,
  }) => _write(
    (dio) => dio.post(
      '/recurring/$id/lines/${lineId ?? id}/extend',
      data: end == null ? null : <String, dynamic>{'end': end},
    ),
  );

  // ---- lines (0.4.3) ----

  Future<RecurringDetail> addLine(String id, RecurringLineWrite line) =>
      _write((dio) => dio.post('/recurring/$id/lines', data: line.toJson()));

  Future<RecurringDetail> updateLine(
    String id,
    String lineId,
    RecurringLineWrite line,
  ) => _write(
    (dio) => dio.put('/recurring/$id/lines/$lineId', data: line.toJson()),
  );

  /// 409 RECURRING_LAST_LINE for the item's only line.
  Future<RecurringDetail> deleteLine(String id, String lineId) =>
      _write((dio) => dio.delete('/recurring/$id/lines/$lineId'));

  Future<RecurringDetail> lineAction(
    String id,
    String lineId,
    RecurringAction action,
  ) => _write((dio) => dio.post('/recurring/$id/lines/$lineId/${action.name}'));

  // ---- plans and installments (0.4.3) ----

  /// The installments a plan would make (nothing saved): the form's table.
  Future<List<PlanInstallment>> planPreview(RecurringPlanWrite plan) =>
      _call((dio) async {
        final res = await dio.post<Map<String, dynamic>>(
          '/recurring/plan-preview',
          data: plan.toJson(),
        );
        return _installments(res.data?['installments']);
      });

  Future<List<PlanInstallment>> installments(String id) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/recurring/$id/installments',
    );
    return _installments(res.data?['data']);
  });

  static List<PlanInstallment> _installments(Object? list) => [
    for (final i in (list as List?) ?? const []) ?PlanInstallment.tryParse(i),
  ];

  /// แก้เฉพาะงวดนี้: only the fields given change.
  Future<RecurringDetail> updateInstallment(
    String id,
    int seq, {
    DateTime? dueDate,
    double? amount,
    double? principal,
    double? interest,
  }) => _write(
    (dio) => dio.put(
      '/recurring/$id/installments/$seq',
      data: {
        'due_date': ?(dueDate == null ? null : ymd(dueDate)),
        'amount': ?amount,
        'principal': ?principal,
        'interest': ?interest,
      },
    ),
  );

  /// จ่ายงวดแล้ว / ยังไม่จ่าย: a tick only, no money.
  Future<RecurringDetail> markInstallment(
    String id,
    int seq, {
    required bool paid,
    String? personalDebtId,
  }) => _write(
    (dio) => dio.post(
      '/recurring/$id/installments/$seq/mark',
      data: {'paid': paid, 'personal_debt_id': ?personalDebtId},
    ),
  );

  /// ปิดแผนก่อนกำหนด: the unticked installments are skipped.
  Future<RecurringDetail> closePlan(String id) =>
      _write((dio) => dio.post('/recurring/$id/plan/close'));

  /// Drops the plan; the item stays.
  Future<RecurringDetail> deletePlan(String id) =>
      _write((dio) => dio.delete('/recurring/$id/plan'));

  /// [from] = a no-end rule's upcoming year starting there (the BE sends
  /// 12 months and `window.next_from`); otherwise by [page].
  Future<ItemPage> items(
    String recurringId, {
    required bool upcoming,
    int page = 1,
    DateTime? from,
  }) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/recurring/$recurringId/items',
      queryParameters: {
        'tab': upcoming ? 'upcoming' : 'produced',
        if (from != null) ...{
          'from': ymd(from),
          'months': 12,
        } else
          'page': page,
      },
    );
    return ItemPage.fromJson(res.data);
  });

  /// Every page of `GET /recurring-items` for these filters.
  Future<List<RecurringItem>> _allItems(Map<String, dynamic> query) =>
      _call((dio) async {
        final out = <RecurringItem>[];
        var page = 1;
        while (true) {
          final res = await dio.get<Map<String, dynamic>>(
            '/recurring-items',
            queryParameters: {...query, 'page': page, 'per_page': 100},
          );
          final p = ItemPage.fromJson(res.data);
          out.addAll(p.items);
          if (!p.hasMore || page >= 20) return out;
          page++;
        }
      });

  static String _month(DateTime m) =>
      '${m.year}-${m.month.toString().padLeft(2, '0')}';

  /// Every occurrence of [month], whatever its status.
  Future<List<RecurringItem>> monthItems(DateTime month) =>
      _allItems({'month': _month(month), 'status': 'all'});

  /// What ต้องจัดการ lists: the due occurrences, plus this month's coming
  /// ones that still need an amount (`needs_amount`). [ruleId] = one rule's.
  Future<List<RecurringItem>> dueItems({String? ruleId}) =>
      _allItems({'status': 'due', 'recurring_rule_id': ?ruleId});

  /// One rule's occurrences around [txDate] for the link picker, and the one
  /// the BE would pick ("งวดใกล้เคียง").
  Future<
    ({List<RecurringItem> items, String? suggestedSlot, String? suggestedLine})
  >
  occurrences(
    String ruleId, {
    DateTime? txDate,
    int past = 3,
    int upcoming = 3,
  }) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/recurring/$ruleId/occurrences',
      queryParameters: {
        if (txDate != null) 'tx_date': ymd(txDate),
        'past': past,
        'upcoming': upcoming,
      },
    );
    final body = res.data ?? const {};
    return (
      items: [
        for (final e in (body['data'] as List?) ?? const [])
          ?RecurringItem.tryParse(e),
      ],
      suggestedSlot: body['suggested_slot'] as String?,
      suggestedLine: body['suggested_recurring_rule_id'] as String?,
    );
  });

  /// A round's address (0.4.3): its item, its line ([ruleId]) and its slot.
  String _occ(String ruleId, String slot) =>
      '/recurring/${RecurringLineIndex.itemOf(ruleId)}/lines/$ruleId'
      '/occurrences/$slot';

  /// One occurrence by its address, stored or computed. The BE has no GET of
  /// one, so it is read from its rule's month list: [date]'s month first (a
  /// moved occurrence), then the slot's. Null when neither has it.
  Future<RecurringItem?> findOccurrence(
    String ruleId,
    String slot, {
    DateTime? date,
  }) async {
    final day = parseYmd(slot);
    final months = {
      if (date != null) DateTime(date.year, date.month),
      if (day != null) DateTime(day.year, day.month),
    };
    for (final m in months) {
      final items = await _allItems({
        'month': _month(m),
        'status': 'all',
        'recurring_rule_id': ruleId,
      });
      for (final i in items) {
        if (i.slot == slot) return i;
      }
    }
    return null;
  }

  Future<ItemWriteResult> _occWrite(
    String path, [
    Map<String, dynamic>? body,
  ]) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(path, data: body);
    return ItemWriteResult.fromJson(res.data!);
  });

  /// ยืนยัน: records the tx now, dated the occurrence's date unless [date].
  Future<ItemWriteResult> confirmOccurrence(
    String ruleId,
    String slot, {
    double? amount,
    DateTime? date,
    String? accountId,
  }) => _occWrite('${_occ(ruleId, slot)}/confirm', {
    'amount': ?amount,
    'date': ?(date == null ? null : ymd(date)),
    'account_id': ?accountId,
  });

  /// ข้าม an open one; a filled one answers 409 (unlink its tx first).
  Future<ItemWriteResult> skipOccurrence(String ruleId, String slot) =>
      _occWrite('${_occ(ruleId, slot)}/skip');

  Future<ItemWriteResult> restoreOccurrence(String ruleId, String slot) =>
      _occWrite('${_occ(ruleId, slot)}/restore');

  /// จ่ายแล้ว without a tx (R5): [amount], else its planned one (400
  /// AMOUNT_REQUIRED with neither).
  Future<ItemWriteResult> markOccurrencePaid(
    String ruleId,
    String slot, {
    double? amount,
  }) => _occWrite('${_occ(ruleId, slot)}/mark-paid', {'amount': ?amount});

  Future<ItemWriteResult> unmarkOccurrencePaid(String ruleId, String slot) =>
      _occWrite('${_occ(ruleId, slot)}/unmark-paid');

  /// หนี้: fills the occurrence with an existing person-book entry of the
  /// rule's person (same debt kind and direction). 409 ITEM_ALREADY_LINKED
  /// when either side is taken, unless [replace].
  Future<ItemWriteResult> linkOccurrenceDebtEntry(
    String ruleId,
    String slot,
    String debtEntryId, {
    bool replace = false,
  }) => _occWrite(
    '${_occ(ruleId, slot)}/link',
    debtEntryLinkBody(debtEntryId, replace: replace),
  );

  /// แก้เฉพาะงวดนี้. Presence-based: a key in [fields] overrides that value,
  /// null clears the override.
  Future<ItemWriteResult> updateOccurrence(
    String ruleId,
    String slot,
    Map<String, dynamic> fields,
  ) => _call((dio) async {
    final res = await dio.put<Map<String, dynamic>>(
      _occ(ruleId, slot),
      data: fields,
    );
    return ItemWriteResult.fromJson(res.data!);
  });

  /// All of an item's due occurrences at once, over every line (0.4.3):
  /// confirm (those with a known amount), mark paid, or skip. `leftOut` says
  /// which stayed and why.
  Future<ItemWriteResult> settleAll(
    String recurringId,
    OccurrenceBulk action,
  ) => _occWrite('/recurring/$recurringId/occurrences/${action.path}');

  /// The picked occurrences of any rules in ONE call (at most [maxBulk]);
  /// `leftOut` says which stayed and why.
  Future<ItemWriteResult> settleMany(
    OccurrenceBulk action,
    List<OccurrenceRef> items,
  ) => _occWrite('/recurring/occurrences/bulk', {
    'action': action.wire,
    'items': [
      for (final i in items)
        {'recurring_rule_id': i.ruleId, 'slot': i.slot, 'amount': ?i.amount},
    ],
  });

  static const maxBulk = 100;

  Future<RecurringItem> getItem(String id) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>('/recurring-items/$id');
    return RecurringItem.fromJson(res.data!);
  });
}

enum RecurringAction { pause, resume, archive, restore, extend }

enum OccurrenceBulk {
  confirm('confirm-ready', 'confirm'),
  markPaid('mark-paid-ready', 'mark_paid'),
  skip('skip-ready', 'skip');

  const OccurrenceBulk(this.path, this.wire);

  /// A rule's all-at-once endpoint.
  final String path;

  /// The `action` of `POST /recurring/occurrences/bulk`.
  final String wire;
}

/// `RecurringLinkRequest` for a หนี้ occurrence: an entry id instead of a
/// transaction id.
Map<String, dynamic> debtEntryLinkBody(
  String debtEntryId, {
  bool replace = false,
}) => {'debt_entry_id': debtEntryId, if (replace) 'replace': true};

/// One row of [RecurringRepository.settleMany]; [amount] is for confirm and
/// mark_paid (R5).
typedef OccurrenceRef = ({String ruleId, String slot, double? amount});
