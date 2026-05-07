import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/contact.dart';

class ContactCreateResult {
  const ContactCreateResult({required this.contact, required this.absorbedCount});
  final Contact contact;
  final int absorbedCount;
}

class ContactsRepository {
  ContactsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

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

  Future<Contact> get(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/contacts/$id');
      return Contact.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ContactCreateResult> create({
    required String displayName,
    String? email,
    String? phone,
    String? notes,
    String? icon,
    List<String>? absorbNames,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/contacts',
        data: <String, dynamic>{
          'display_name': displayName,
          'email': ?email,
          'phone': ?phone,
          'notes': ?notes,
          'icon': ?icon,
          'absorb_names': ?absorbNames,
        },
      );
      return ContactCreateResult(
        contact: Contact.fromJson(res.data!['contact'] as Map<String, dynamic>),
        absorbedCount: (res.data!['absorbed_count'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Contact> update(String id, {
    String? displayName,
    String? email,
    String? phone,
    String? notes,
    String? icon,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/contacts/$id',
        data: <String, dynamic>{
          'display_name': ?displayName,
          'email': ?email,
          'phone': ?phone,
          'notes': ?notes,
          'icon': ?icon,
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

  Future<int> delete(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>('/contacts/$id');
      return (res.data?['splits_restored'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> absorb(String id, List<String> names) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/contacts/$id/absorb',
        data: <String, dynamic>{'names': names},
      );
      return (res.data?['absorbed_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /contacts/:id/request-link`. Privacy-preserving: same response on
  /// hit and miss.
  Future<void> requestLink(String id) async {
    try {
      await _client.dio.post<dynamic>('/contacts/$id/request-link');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /contacts/link-requests/:notification_id/sender-profile` —
  /// returns the sender's display_name + email + icon for pre-filling
  /// the contact form during the inbox tap flow. BE gates this to the
  /// recipient while the request is still pending.
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
  /// Does NOT touch the caller's address book; that's a separate
  /// post-accept tap-flow step (see [createLinkedContactFromLinkRequest]
  /// / [linkExistingContactFromLinkRequest]).
  Future<Contact> acceptLinkRequest(String notificationId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/contacts/link-requests/$notificationId/accept',
      );
      return Contact.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /contacts/link-requests/:notification_id/reject` — marks the
  /// recipient's notification dismissed. Silent on the sender's side.
  Future<void> rejectLinkRequest(String notificationId) async {
    try {
      await _client.dio.post<dynamic>(
        '/contacts/link-requests/$notificationId/reject',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /contacts/link-requests/:notification_id/create-linked-contact`
  ///
  /// Post-accept "no existing contact, create one" — the BE pulls
  /// display_name + email from the sender's user record (so the snapshot
  /// is correct as a fallback if the contact is later unlinked). Phone /
  /// notes / icon come from the form.
  Future<Contact> createLinkedContactFromLinkRequest(
    String notificationId, {
    String? phone,
    String? notes,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/contacts/link-requests/$notificationId/create-linked-contact',
        data: <String, dynamic>{
          'phone': ?phone,
          'notes': ?notes,
        },
      );
      return Contact.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /contacts/link-requests/:notification_id/link-existing-contact/:contact_id`
  ///
  /// Post-accept "I already have a contact for them, just wire the link"
  /// — the BE sets `linked_user_id` on the existing caller-owned contact.
  /// `display_name` and `email` are NOT sent — those project from the
  /// linked user once the contact is linked. Phone / notes / icon are
  /// optional B-side updates.
  Future<Contact> linkExistingContactFromLinkRequest(
    String notificationId,
    String contactId, {
    String? phone,
    String? notes,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/contacts/link-requests/$notificationId/link-existing-contact/$contactId',
        data: <String, dynamic>{
          'phone': ?phone,
          'notes': ?notes,
        },
      );
      return Contact.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

  Future<Contact> _post(String path) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(path);
      return Contact.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
