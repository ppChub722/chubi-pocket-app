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

  /// Lightweight badge poll — `GET /notifications/unread-count`.
  Future<int> unreadCount() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      return (res.data?['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<NotificationActionResult> markRead(String id) =>
      _post('/notifications/$id/read');

  Future<NotificationActionResult> markActioned(String id) =>
      _post('/notifications/$id/actioned');

  Future<NotificationActionResult> markDismissed(String id) =>
      _post('/notifications/$id/dismiss');

  /// Marks everything read; returns the fresh badges.
  Future<Badges> markReadAll() async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/notifications/read-all',
      );
      return Badges.fromJson(res.data!['badges'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Hard delete; returns the fresh badges.
  Future<Badges> delete(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/notifications/$id',
      );
      return Badges.fromJson(res.data!['badges'] as Map<String, dynamic>);
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

  /// `PUT /v1/notifications/settings` — partial; lists replace wholesale.
  Future<NotificationSettings> updateSettings({
    Set<String>? mutedTypes,
    Set<String>? autoTypes,
    String? defaultAccountId,
    bool clearDefaultAccount = false,
    bool? autoResolveOwnInProjects,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/notifications/settings',
        data: <String, dynamic>{
          if (mutedTypes != null) 'muted_types': mutedTypes.toList(),
          if (autoTypes != null) 'auto_types': autoTypes.toList(),
          'auto_resolve_own_in_projects': ?autoResolveOwnInProjects,
          // Explicit null clears it (contract §5).
          if (clearDefaultAccount)
            'default_account_id': null
          else
            'default_account_id': ?defaultAccountId,
        },
      );
      return NotificationSettings.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<NotificationActionResult> _post(String path) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(path);
      return NotificationActionResult(
        notification: AppNotification.fromJson(
          res.data!['notification'] as Map<String, dynamic>,
        ),
        badges: Badges.fromJson(res.data!['badges'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
