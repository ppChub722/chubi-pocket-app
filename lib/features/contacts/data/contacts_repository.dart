import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../notifications/domain/notification.dart';
import '../domain/contact.dart';
import '../../../ui/ui.dart';

/// `{contact, notification, badges}` of a link-request action. [contact] is
/// null for accept (the linked contact belongs to the sender) and reject.
class LinkRequestResult {
  const LinkRequestResult({
    required this.contact,
    required this.notification,
    required this.badges,
  });
  final Contact? contact;
  final AppNotification notification;
  final Map<String, dynamic> badges;

  factory LinkRequestResult.fromJson(Map<String, dynamic> json) =>
      LinkRequestResult(
        contact: json['contact'] != null
            ? Contact.fromJson(json['contact'] as Map<String, dynamic>)
            : null,
        notification: AppNotification.fromJson(
          json['notification'] as Map<String, dynamic>,
        ),
        badges: (json['badges'] as Map<String, dynamic>?) ?? const {},
      );
}

class ContactsRepository {
  ContactsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

  /// `GET /contacts` — the server orders (active first, then resolved name,
  /// case-insensitive) and searches name / nickname / display_name / email.
  Future<List<Contact>> list({
    String? status,
    bool? linked,
    String? search,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/contacts',
        queryParameters: <String, dynamic>{
          'status': ?status,
          'linked': ?linked?.toString(),
          'search': ?search,
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(Contact.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /contacts/:id?include=unlinked_names` — one call: the contact plus
  /// the split names still free to wire to it.
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
    }
  }

  /// Partial update. A null argument is left out of the body (unchanged);
  /// an empty [nickname] is sent as an explicit `null` (clears it).
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
    }
  }

  Future<Contact> archive(String id) => _post('/contacts/$id/archive');
  Future<Contact> restore(String id) => _post('/contacts/$id/restore');
  Future<Contact> unlink(String id) => _post('/contacts/$id/unlink');

  /// `POST /contacts/:id/request-link`. Privacy-preserving: same response on
  /// hit and miss. Returns the contact.
  Future<Contact> requestLink(String id) => _post('/contacts/$id/request-link');

  Future<DeleteContactResult> delete(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/contacts/$id',
      );
      return DeleteContactResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
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
    }
  }

  /// `GET /contacts/link-requests/:notification_id/sender-profile` —
  /// the sender's display_name + email + icon (+ the caller's `contact_id`
  /// that already links to them) for the inbox tap flow.
  Future<SenderProfile> senderProfile(String notificationId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/contacts/link-requests/$notificationId/sender-profile',
      );
      return SenderProfile.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /contacts/link-requests/:notification_id/accept` — links the
  /// sender's contact to the caller and marks the notification actioned.
  /// Returns `contact: null`; the post-accept tap-flow step creates / links
  /// the caller's own contact separately.
  Future<LinkRequestResult> acceptLinkRequest(String notificationId) =>
      _linkAction('/contacts/link-requests/$notificationId/accept');

  /// `POST /contacts/link-requests/:notification_id/reject` — marks the
  /// recipient's notification dismissed. Silent on the sender's side.
  Future<LinkRequestResult> rejectLinkRequest(String notificationId) =>
      _linkAction('/contacts/link-requests/$notificationId/reject');

  /// `POST /contacts/link-requests/:notification_id/create-linked-contact`
  ///
  /// Post-accept "no existing contact, create one" — the BE pulls
  /// display_name + email from the sender's user record. Phone /
  /// description / note come from the form.
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

  /// `POST /contacts/link-requests/:notification_id/link-existing-contact/:contact_id`
  ///
  /// Post-accept "I already have a contact for them, just wire the link".
  /// Phone / description / note are optional B-side updates.
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

  /// `GET /contacts/unlinked-names` — create-sheet suggestions only (the
  /// detail page gets its names from [get]).
  Future<List<UnlinkedName>> unlinkedNames() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/contacts/unlinked-names',
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(UnlinkedName.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
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
    }
  }

  Future<Contact> _post(String path) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(path);
      return Contact.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
