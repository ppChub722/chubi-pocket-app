import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../ui/ui.dart';
import '../../pending/domain/pending_transaction.dart';
import '../domain/recurrence_rule.dart' show ymd;
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';
import '../domain/recurring_summary.dart';

/// The recurring list + its filter counts (`listRecurring`, one call).
class RecurringList {
  const RecurringList({
    this.items = const [],
    this.counts = const {},
    this.page = 1,
    this.totalPages = 1,
    this.summary,
  });

  final List<Recurring> items;

  /// The summary card's numbers (`summary`); null when absent.
  final RecurringSummary? summary;

  /// {current, archived, all} → n.
  final Map<String, int> counts;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// `/recurring` + `/recurring-items` (openapi tag Recurring). Every write
/// returns the new state; the due check runs inside every recurring read, so
/// a pull-to-refresh is a recheck.
class RecurringRepository {
  RecurringRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// The app-wide instance (provided in app.dart).
  static RecurringRepository of(BuildContext context) =>
      context.read<RecurringRepository>();

  Future<T> _call<T>(Future<T> Function(Dio dio) run) async {
    try {
      return await run(_client.dio);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Recurrings ──────────────────────────────────────────────────────

  /// `listRecurring`.
  Future<RecurringList> list({
    RecurringFilter filter = RecurringFilter.current,
    int page = 1,
    String q = '',
  }) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/recurring',
      queryParameters: {
        'status': filter.toJson(),
        'page': page,
        if (q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    final body = res.data!;
    final counts = body['counts'];
    final p = body['pagination'] as Map<String, dynamic>?;
    return RecurringList(
      items: [
        for (final e in (body['data'] as List?) ?? const [])
          Recurring.fromJson(e as Map<String, dynamic>),
      ],
      counts: {
        if (counts is Map<String, dynamic>)
          for (final e in counts.entries)
            e.key: (e.value as num?)?.toInt() ?? 0,
      },
      page: (p?['page'] as num?)?.toInt() ?? 1,
      totalPages: (p?['total_pages'] as num?)?.toInt() ?? 1,
      summary: RecurringSummary.fromJson(body['summary']),
    );
  });

  /// `getRecurring`: the setting + its first produced items.
  Future<RecurringDetail> get(String id) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>('/recurring/$id');
    return RecurringDetail.fromJson(res.data!);
  });

  /// `createRecurring`.
  Future<RecurringDetail> create(RecurringWrite write) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/recurring',
      data: write.toJson(),
    );
    return RecurringDetail.fromJson(res.data!);
  });

  /// `updateRecurring`: a rule / start / end change rebuilds the upcoming
  /// items; [scope] (upcoming | all) says which items take the field changes;
  /// [alsoUpdateLink] (with all) changes their drafts / transactions too.
  Future<RecurringDetail> update(
    String id,
    RecurringWrite write, {
    EditScope scope = EditScope.upcoming,
    bool alsoUpdateLink = false,
  }) => _call((dio) async {
    final res = await dio.put<Map<String, dynamic>>(
      '/recurring/$id',
      data: {
        ...write.toJson(forUpdate: true),
        'scope': scope.toJson(),
        'also_update_link': alsoUpdateLink,
      },
    );
    return RecurringDetail.fromJson(res.data!);
  });

  /// `duplicateRecurring`: a new ACTIVE copy starting today → its page.
  Future<RecurringDetail> duplicate(String id) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/recurring/$id/duplicate',
    );
    return RecurringDetail.fromJson(res.data!);
  });

  /// `deleteRecurring` → the wallet balances it moved.
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

  /// `pauseRecurring` / `resumeRecurring` / `archiveRecurring` /
  /// `restoreRecurring` / `extendRecurring`.
  /// One literal path per op (the hub's endpoint scan reads them).
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

  /// `extendRecurring` with the new end (`{kind: date|count, date|count}`);
  /// null `end` = a setting with no end (the BE writes one more block).
  Future<RecurringDetail> extend(String id, {Map<String, dynamic>? end}) =>
      _call((dio) async {
        final res = await dio.post<Map<String, dynamic>>(
          '/recurring/$id/extend',
          data: end == null ? null : <String, dynamic>{'end': end},
        );
        return RecurringDetail.fromJson(res.data!);
      });

  // ── Items ───────────────────────────────────────────────────────────

  /// `listRecurringRuleItems`: one recurring's produced or upcoming items.
  Future<ItemPage> items(
    String recurringId, {
    required bool upcoming,
    int page = 1,
  }) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/recurring/$recurringId/items',
      queryParameters: {
        'tab': upcoming ? 'upcoming' : 'produced',
        'page': page,
      },
    );
    return ItemPage.fromJson(res.data);
  });

  /// `listRecurringItems?month=`: the calendar — every item dated in [month]
  /// (YYYY-MM), every status, oldest first, one page of up to 100.
  Future<ItemPage> calendar(DateTime month) => _call((dio) async {
    final mm = month.month.toString().padLeft(2, '0');
    final res = await dio.get<Map<String, dynamic>>(
      '/recurring-items',
      queryParameters: {'month': '${month.year}-$mm'},
    );
    return ItemPage.fromJson(res.data);
  });

  /// `updateRecurringItem` for ONE occurrence: a new [date] and / or
  /// [amount] (scope this). The date / amount stay as they are when null.
  Future<ItemWriteResult> editOccurrence(
    String id, {
    DateTime? date,
    double? amount,
  }) => _call((dio) async {
    final res = await dio.put<Map<String, dynamic>>(
      '/recurring-items/$id',
      data: {
        'date': ?(date == null ? null : ymd(date)),
        'amount': ?amount,
        'scope': 'this',
      },
    );
    return ItemWriteResult.fromJson(res.data!);
  });

  /// `createRecurringItem`: a manual item on a recurring (or a one-off when
  /// [recurringId] is null).
  Future<ItemWriteResult> addItem(String? recurringId, PendingDraft values) =>
      _call((dio) async {
        final res = await dio.post<Map<String, dynamic>>(
          '/recurring-items',
          data: {'recurring_id': recurringId, ...itemFieldsJson(values)},
        );
        return ItemWriteResult.fromJson(res.data!);
      });

  /// `updateRecurringItem`.
  Future<ItemWriteResult> updateItem(
    String id,
    PendingDraft values, {
    EditScope scope = EditScope.thisOne,
    bool alsoUpdateLink = false,
  }) => _call((dio) async {
    final res = await dio.put<Map<String, dynamic>>(
      '/recurring-items/$id',
      data: {
        ...itemFieldsJson(values),
        'scope': scope.toJson(),
        'also_update_link': alsoUpdateLink,
      },
    );
    return ItemWriteResult.fromJson(res.data!);
  });

  /// `deleteRecurringItem`.
  Future<ItemWriteResult> deleteItem(
    String id, {
    required bool deleteLinkedTx,
  }) => _call((dio) async {
    final res = await dio.delete<Map<String, dynamic>>(
      '/recurring-items/$id',
      queryParameters: {'delete_linked_tx': deleteLinkedTx},
    );
    return ItemWriteResult.fromJson(res.data ?? {'id': id});
  });

  /// `createFromRecurringItem`: "สร้างใหม่" → a pending draft or a real tx;
  /// [values] may change any field incl. the date (after today = upcoming).
  Future<ItemWriteResult> createFromItem(
    String id,
    ItemTarget target, {
    PendingDraft? values,
  }) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/recurring-items/$id/create',
      data: {
        'target': target.toJson(),
        if (values != null) 'fields': itemFieldsJson(values),
      },
    );
    return ItemWriteResult.fromJson(res.data!);
  });

  /// `archiveRecurringItem` / `restoreRecurringItem`.
  Future<ItemWriteResult> setItemArchived(
    String id, {
    required bool archived,
  }) => _call((dio) async {
    final res = archived
        ? await dio.post<Map<String, dynamic>>('/recurring-items/$id/archive')
        : await dio.post<Map<String, dynamic>>('/recurring-items/$id/restore');
    return ItemWriteResult.fromJson(res.data!);
  });

  /// `batchRecurringItems`: one call for the selected items.
  Future<ItemWriteResult> batch(
    List<String> ids,
    ItemBatchAction action, {
    ItemTarget? target,
    bool? deleteLinkedTx,
  }) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/recurring-items/batch',
      data: {
        'ids': ids,
        'action': action.name,
        'target': ?target?.toJson(),
        'delete_linked_tx': ?deleteLinkedTx,
      },
    );
    return ItemWriteResult.fromJson(res.data!);
  });
}

/// The one-call lifecycle moves of a recurring.
enum RecurringAction { pause, resume, archive, restore, extend }

/// The batch moves on selected items.
enum ItemBatchAction { create, archive, restore, delete }
