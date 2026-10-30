import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/contacts/data/contacts_repository.dart';
import 'package:chubi_pocket/features/contacts/domain/contact.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

/// Records the request; answers with [body].
class _Adapter implements HttpClientAdapter {
  Object? body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A contact as the BE sends it (linked user, resolved name / icon, unlinked
/// split names).
Map<String, dynamic> _prodContact() => {
  'id': 'c1',
  'name': 'Lee Cooper',
  'nickname': 'Coop',
  'show_nickname': true,
  'display_name': 'Lee Cooper',
  'email': 'lee@example.com',
  'phone': null,
  'description': 'Flatmate',
  'note': null,
  'icon_code': null,
  'linked_user': {
    'id': 'u9',
    'display_name': 'Lee',
    'username': 'lee',
    'email': 'lee@example.com',
    'icon_code': null,
  },
  'status': 'active',
  'last_used_at': '2026-10-10T08:00:00Z',
  'created_at': '2026-10-01T08:00:00Z',
  'updated_at': '2026-10-11T08:00:00Z',
  'unlinked_total': {'names': 1, 'records': 2},
  'delete_preview': null,
  'unlinked_names': [
    {'name': 'Cooper', 'count': 2},
  ],
};

void main() {
  test('prod-shaped JSON parses; a malformed body throws', () {
    final d = ContactDetail.fromJson(_prodContact());
    expect(d.contact.displayName, 'Lee Cooper');
    expect(d.contact.nickname, 'Coop');
    expect(d.contact.showNickname, isTrue);
    expect(d.contact.phone, isNull);
    expect(d.contact.isLinked, isTrue);
    expect(d.contact.linkedUser!.id, 'u9');
    expect(d.contact.linkedUser!.username, 'lee');
    expect(d.unlinkedNameCount, 1);
    expect(d.unlinkedRecordCount, 2);
    expect(d.unlinkedNames.single.name, 'Cooper');
    expect(d.unlinkedNames.single.count, 2);
    expect(d.deletePreview, isNull);

    final withPreview = ContactDetail.fromJson({
      ..._prodContact(),
      'show_nickname': null,
      'linked_user': null,
      'delete_preview': {'debt_records': 3, 'event_members': 2, 'linked': true},
    });
    expect(withPreview.contact.showNickname, isTrue);
    expect(withPreview.contact.isLinked, isFalse);
    expect(withPreview.deletePreview!.debtRecords, 3);
    expect(withPreview.deletePreview!.eventMembers, 2);
    expect(withPreview.deletePreview!.linked, isTrue);

    expect(() => ContactDetail.fromJson({'id': 'c1'}), throwsA(isA<Error>()));
  });

  test(
    'repository: show_nickname alone in the update; detail includes',
    () async {
      final http = _Adapter();
      final repo = ContactsRepository(
        client: _FakeApi(Dio()..httpClientAdapter = http),
      );

      http.body = {..._prodContact(), 'show_nickname': false};
      final updated = await repo.update('c1', showNickname: false);
      expect(updated.showNickname, isFalse);
      expect(http.last!.method, 'PUT');
      expect(http.last!.path, '/contacts/c1');
      expect(http.last!.data, {'show_nickname': false});

      http.body = _prodContact();
      await repo.get('c1');
      expect(http.last!.queryParameters, {'include': 'unlinked_names'});
      await repo.get('c1', deletePreview: true);
      expect(http.last!.queryParameters, {
        'include': 'unlinked_names,delete_preview',
      });
    },
  );
}
