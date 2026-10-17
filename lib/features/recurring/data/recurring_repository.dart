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

class RecurringList {
  const RecurringList({
    this.items = const [],
    this.counts = const {},
    this.page = 1,
    this.totalPages = 1,
    this.summary,
  });

  final List<Recurring> items;

  final RecurringSummary? summary;

  final Map<String, int> counts;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

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

  Future<ItemPage> calendar(DateTime month) => _call((dio) async {
    final mm = month.month.toString().padLeft(2, '0');
    final res = await dio.get<Map<String, dynamic>>(
      '/recurring-items',
      queryParameters: {'month': '${month.year}-$mm'},
    );
    return ItemPage.fromJson(res.data);
  });

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

  Future<ItemWriteResult> addItem(String? recurringId, PendingDraft values) =>
      _call((dio) async {
        final res = await dio.post<Map<String, dynamic>>(
          '/recurring-items',
          data: {'recurring_id': recurringId, ...itemFieldsJson(values)},
        );
        return ItemWriteResult.fromJson(res.data!);
      });

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

  Future<ItemWriteResult> setItemArchived(
    String id, {
    required bool archived,
  }) => _call((dio) async {
    final res = archived
        ? await dio.post<Map<String, dynamic>>('/recurring-items/$id/archive')
        : await dio.post<Map<String, dynamic>>('/recurring-items/$id/restore');
    return ItemWriteResult.fromJson(res.data!);
  });

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

enum RecurringAction { pause, resume, archive, restore, extend }

enum ItemBatchAction { create, archive, restore, delete }
