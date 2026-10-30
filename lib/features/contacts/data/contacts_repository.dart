import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../notifications/domain/notification.dart';
import '../domain/contact.dart';
import '../../../ui/ui.dart';

class LinkRequestResult {
  const LinkRequestResult({
    required this.contact,
    required this.notification,
    required this.badges,
    this.summary = const InboxSummary(),
  });
  final Contact? contact;
  final AppNotification notification;
  final Map<String, dynamic> badges;

  final InboxSummary summary;

  NotificationActionResult get answer => NotificationActionResult(
    notification: notification,
    badges: Badges.fromJson(badges),
    summary: summary,
  );

  factory LinkRequestResult.fromJson(Map<String, dynamic> json) =>
      LinkRequestResult(
        contact: json['contact'] != null
            ? Contact.fromJson(json['contact'] as Map<String, dynamic>)
            : null,
        notification: AppNotification.fromJson(
          json['notification'] as Map<String, dynamic>,
        ),
        badges: (json['badges'] as Map<String, dynamic>?) ?? const {},
        summary: InboxSummary.fromJson(
          (json['summary'] as Map?)?.cast<String, dynamic>(),
        ),
      );
}

class ContactsRepository {
  ContactsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

  Future<ContactDetail> get(String id, {bool deletePreview = false}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/contacts/$id',
        queryParameters: {
          'include': deletePreview
              ? 'unlinked_names,delete_preview'
              : 'unlinked_names',
        },
      );
      return ContactDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<AbsorbResult> create({
    required String displayName,
    String? nickname,
    bool? showNickname,
    String? email,
    String? phone,
    String? description,
    String? note,
    IconCode? iconCode,
    List<String>? absorbNames,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/contacts',
        data: <String, dynamic>{
          'display_name': displayName,
          'nickname': ?(nickname == null || nickname.isEmpty ? null : nickname),
          'show_nickname': ?showNickname,
          'email': ?email,
          'phone': ?phone,
          'description': ?description,
          'note': ?note,
          if (iconCode != null) 'icon_code': iconCode.toJson(),
          'absorb_names': ?absorbNames,
        },
      );
      return AbsorbResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<Contact> update(
    String id, {
    String? displayName,
    String? nickname,
    bool? showNickname,
    String? email,
    String? phone,
    String? description,
    String? note,
    IconCode? iconCode,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/contacts/$id',
        data: <String, dynamic>{
          'display_name': ?displayName,
          if (nickname != null) 'nickname': nickname.isEmpty ? null : nickname,
          'show_nickname': ?showNickname,
          'email': ?email,
          'phone': ?phone,
          'description': ?description,
          'note': ?note,
          if (iconCode != null) 'icon_code': iconCode.toJson(),
        },
      );
      return Contact.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<Contact> archive(String id) => _post('/contacts/$id/archive');
  Future<Contact> restore(String id) => _post('/contacts/$id/restore');
  Future<Contact> unlink(String id) => _post('/contacts/$id/unlink');

  Future<Contact> requestLink(String id) => _post('/contacts/$id/request-link');

  Future<DeleteContactResult> delete(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/contacts/$id',
      );
      return DeleteContactResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<AbsorbResult> absorb(String id, List<String> names) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/contacts/$id/absorb',
        data: <String, dynamic>{'names': names},
      );
      return AbsorbResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<SenderProfile> senderProfile(String notificationId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/contacts/link-requests/$notificationId/sender-profile',
      );
      return SenderProfile.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<LinkRequestResult> acceptLinkRequest(String notificationId) =>
      _linkAction('/contacts/link-requests/$notificationId/accept');

  Future<LinkRequestResult> rejectLinkRequest(String notificationId) =>
      _linkAction('/contacts/link-requests/$notificationId/reject');

  Future<LinkRequestResult> createLinkedContactFromLinkRequest(
    String notificationId, {
    String? phone,
    String? description,
    String? note,
  }) => _linkAction(
    '/contacts/link-requests/$notificationId/create-linked-contact',
    data: <String, dynamic>{
      'phone': ?phone,
      'description': ?description,
      'note': ?note,
    },
  );

  Future<LinkRequestResult> linkExistingContactFromLinkRequest(
    String notificationId,
    String contactId, {
    String? phone,
    String? description,
    String? note,
  }) => _linkAction(
    '/contacts/link-requests/$notificationId/link-existing-contact/$contactId',
    data: <String, dynamic>{
      'phone': ?phone,
      'description': ?description,
      'note': ?note,
    },
  );

  Future<List<UnlinkedName>> unlinkedNames() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/contacts/unlinked-names',
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(UnlinkedName.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<LinkRequestResult> _linkAction(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        path,
        data: data,
      );
      return LinkRequestResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<Contact> _post(String path) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(path);
      return Contact.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }
}
