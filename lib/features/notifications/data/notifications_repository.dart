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
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// `/v1/notifications/*` endpoints. Spec §13.3.
class NotificationsRepository {
  NotificationsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<NotificationsPage> list({
    String? read,
    String? actioned,
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
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Lightweight badge poll — spec §13.4.8 (in-app polling in 1b).
  Future<int> unreadCount() async {
    final page = await list(read: 'false', perPage: 1);
    return page.unreadCount;
  }

  Future<AppNotification> markRead(String id) async {
    return _post('/notifications/$id/read');
  }

  Future<AppNotification> markActioned(String id) async {
    return _post('/notifications/$id/actioned');
  }

  Future<AppNotification> markDismissed(String id) async {
    return _post('/notifications/$id/dismiss');
  }

  Future<int> markReadAll() async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/notifications/read-all',
      );
      return (res.data?['marked_read'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<dynamic>('/notifications/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
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
    }
  }

  Future<NotificationSettings> updateSettings({
    bool? autoNotifyLinkedSplitContacts,
    bool? autoAddToPersonalDebtOnSplitNotification,
    bool? autoRecordReceivedPayment,
    bool? autoResolveOwnInProjects,
    String? defaultAccountId,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/notifications/settings',
        data: <String, dynamic>{
          'auto_notify_linked_split_contacts': ?autoNotifyLinkedSplitContacts,
          'auto_add_to_personal_debt_on_split_notification':
              ?autoAddToPersonalDebtOnSplitNotification,
          'auto_record_received_payment': ?autoRecordReceivedPayment,
          'auto_resolve_own_in_projects': ?autoResolveOwnInProjects,
          'default_account_id': ?defaultAccountId,
        },
      );
      return NotificationSettings.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppNotification> _post(String path) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(path);
      return AppNotification.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
