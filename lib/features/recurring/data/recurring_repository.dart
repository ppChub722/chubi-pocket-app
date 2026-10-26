import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../ui/ui.dart';
import '../domain/recurrence_rule.dart' show parseYmd, ymd;
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';

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
    }
  }

  Future<RecurringDetail> get(String id, {bool deletePreview = false}) =>
      _call((dio) async {
        final res = await dio.get<Map<String, dynamic>>(
          '/recurring/$id',
          queryParameters: deletePreview
              ? const {'include': 'delete_preview'}
              : null,
        );
        return RecurringDetail.fromJson(res.data!);
      });

  Future<RecurringDetail> create(RecurringWrite write) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/recurring',
      data: write.toJson(),
    );
    return RecurringDetail.fromJson(res.data!);
  });

  Future<RecurringDetail> update(
    String id,
    RecurringWrite write, {
    EditScope scope = EditScope.upcoming,
    bool alsoUpdateLink = false,
    bool alsoUpdateTx = false,
  }) => _call((dio) async {
    final res = await dio.put<Map<String, dynamic>>(
      '/recurring/$id',
      data: {
        ...write.toJson(forUpdate: true),
        'scope': scope.toJson(),
        'also_update_link': alsoUpdateLink,
        'also_update_tx': alsoUpdateTx,
      },
    );
    return RecurringDetail.fromJson(res.data!);
  });

  Future<RecurringDetail> duplicate(String id) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/recurring/$id/duplicate',
    );
    return RecurringDetail.fromJson(res.data!);
  });

  Future<Map<String, double>> delete(
    String id, {
    required bool deleteLinkedTxs,
  }) => _call((dio) async {
    final res = await dio.delete<Map<String, dynamic>>(
      '/recurring/$id',
      queryParameters: {'delete_linked_txs': deleteLinkedTxs},
    );
    return ItemWriteResult.fromJson(res.data ?? const {}).balances;
  });

  Future<RecurringDetail> action(String id, RecurringAction action) =>
      _call((dio) async {
        final res = await switch (action) {
          RecurringAction.pause => dio.post<Map<String, dynamic>>(
            '/recurring/$id/pause',
          ),
          RecurringAction.resume => dio.post<Map<String, dynamic>>(
            '/recurring/$id/resume',
          ),
          RecurringAction.archive => dio.post<Map<String, dynamic>>(
            '/recurring/$id/archive',
          ),
          RecurringAction.restore => dio.post<Map<String, dynamic>>(
            '/recurring/$id/restore',
          ),
          RecurringAction.extend => dio.post<Map<String, dynamic>>(
            '/recurring/$id/extend',
          ),
        };
        return RecurringDetail.fromJson(res.data!);
      });

  Future<RecurringDetail> extend(String id, {Map<String, dynamic>? end}) =>
      _call((dio) async {
        final res = await dio.post<Map<String, dynamic>>(
          '/recurring/$id/extend',
          data: end == null ? null : <String, dynamic>{'end': end},
        );
        return RecurringDetail.fromJson(res.data!);
      });

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
      _allItems({'status': 'due', 'rule_id': ?ruleId});

  /// One rule's occurrences around [txDate] for the link picker, and the one
  /// the BE would pick ("งวดใกล้เคียง").
  Future<({List<RecurringItem> items, String? suggestedSlot})> occurrences(
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
    );
  });

  String _occ(String ruleId, String slot) =>
      '/recurring/$ruleId/occurrences/$slot';

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
        'rule_id': ruleId,
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

  /// ข้าม; [deleteTx] also deletes the tx it is linked to.
  Future<ItemWriteResult> skipOccurrence(
    String ruleId,
    String slot, {
    bool? deleteTx,
  }) => _occWrite('${_occ(ruleId, slot)}/skip', {'delete_tx': ?deleteTx});

  Future<ItemWriteResult> restoreOccurrence(String ruleId, String slot) =>
      _occWrite('${_occ(ruleId, slot)}/restore');

  /// จ่ายแล้ว without a tx.
  Future<ItemWriteResult> markOccurrencePaid(String ruleId, String slot) =>
      _occWrite('${_occ(ruleId, slot)}/mark-paid');

  Future<ItemWriteResult> unmarkOccurrencePaid(String ruleId, String slot) =>
      _occWrite('${_occ(ruleId, slot)}/unmark-paid');

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

  /// All of a rule's due occurrences at once: confirm (those with a known
  /// amount), mark paid, or skip. `leftOut` says which stayed and why.
  Future<ItemWriteResult> settleAll(String ruleId, OccurrenceBulk action) =>
      _occWrite('/recurring/$ruleId/occurrences/${action.path}');

  /// The picked occurrences of any rules in ONE call (at most [maxBulk]);
  /// `leftOut` says which stayed and why.
  Future<ItemWriteResult> settleMany(
    OccurrenceBulk action,
    List<OccurrenceRef> items,
  ) => _occWrite('/recurring/occurrences/bulk', {
    'action': action.wire,
    'items': [
      for (final i in items)
        {'rule_id': i.ruleId, 'slot': i.slot, 'amount': ?i.amount},
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

/// One row of [RecurringRepository.settleMany]; [amount] is for confirm only.
typedef OccurrenceRef = ({String ruleId, String slot, double? amount});
