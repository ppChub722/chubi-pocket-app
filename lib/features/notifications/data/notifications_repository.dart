import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/notification.dart';

class NotificationsPage {
  const NotificationsPage({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    this.summary = const InboxSummary(),
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  final InboxSummary summary;

  bool get hasMore => page < totalPages;
}

class NotificationsRepository {
  NotificationsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<NotificationsPage> list({
    String? read,
    String? actioned,
    String? dismissed,
    String? awaitsAnswer,
    String? type,
    String? from,
    String? to,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: <String, dynamic>{
          'read': ?read,
          'actioned': ?actioned,
          'dismissed': ?dismissed,
          'awaits_answer': ?awaitsAnswer,
          'type': ?type,
          'from': ?from,
          'to': ?to,
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      final pag = res.data!['pagination'] as Map<String, dynamic>;
      return NotificationsPage(
        notifications: data.map(AppNotification.fromJson).toList(),
        unreadCount: (res.data!['unread_count'] as num?)?.toInt() ?? 0,
        page: pag['page'] as int,
        perPage: pag['per_page'] as int,
        total: pag['total'] as int,
        totalPages: pag['total_pages'] as int,
        summary: InboxSummary.fromJson(
          res.data!['summary'] as Map<String, dynamic>?,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      return (res.data?['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<NotificationActionResult> markRead(String id) =>
      _post('/notifications/$id/read');

  Future<NotificationActionResult> markActioned(String id) =>
      _post('/notifications/$id/actioned');

  Future<NotificationActionResult> restore(String id) =>
      _post('/notifications/$id/restore');

  Future<NotificationActionResult> markDismissed(String id) =>
      _post('/notifications/$id/dismiss');

  Future<InboxCounts> markReadAll() async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/notifications/read-all',
      );
      return InboxCounts.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<InboxCounts> delete(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/notifications/$id',
      );
      return InboxCounts.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<NotificationSettings> getSettings() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/notifications/settings',
      );
      return NotificationSettings.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  /// Partial: only what is passed changes ([mutedTypes] replaces the list).
  Future<NotificationSettings> updateSettings({
    Set<String>? mutedTypes,
    bool? autoSyncEvents,
    bool? autoSyncDebts,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/notifications/settings',
        data: <String, dynamic>{
          if (mutedTypes != null) 'muted_types': mutedTypes.toList(),
          'auto_sync_events': ?autoSyncEvents,
          'auto_sync_debts': ?autoSyncDebts,
        },
      );
      return NotificationSettings.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<NotificationActionResult> _post(String path) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(path);
      return NotificationActionResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }
}
