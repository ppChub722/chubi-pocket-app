import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/domain/wallet_member.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/connections/data/connections_repository.dart';
import 'package:chubi_pocket/features/connections/domain/connection.dart';
import 'package:chubi_pocket/features/contacts/domain/contact.dart';
import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/users/data/users_repository.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

/// Records the request; answers [body] with [status].
class _Adapter implements HttpClientAdapter {
  Object? body;
  int status = 200;
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
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The openapi `Connection` example (Telegram, linked, with a photo).
Map<String, dynamic> _telegram() => {
  'provider': 'telegram',
  'name': 'Telegram',
  'brand_color': '#26A5E4',
  'logo_url': '/api/v1/brand-logos/telegram.png?v=1',
  'available': true,
  'linked': true,
  'account': '@nong',
  'linked_at': '2026-10-28T09:00:00Z',
  'photo': {
    'source': 'telegram',
    'url': '/api/v1/avatars/0191c2a0-0000-7000-8000-0000000000cc?v=2',
    'imported_at': '2026-10-28T09:01:00Z',
  },
  'permissions': [
    {'key': 'chat', 'available': true, 'on': true},
    {'key': 'ask', 'available': false, 'on': false},
    {'key': 'slip', 'available': false, 'on': false},
    {'key': 'notify', 'available': false, 'on': false},
  ],
};

Map<String, dynamic> _line() => {
  'provider': 'line',
  'name': 'LINE',
  'brand_color': '#06C755',
  'logo_url': '/api/v1/brand-logos/line.png?v=1',
  'available': false,
  'linked': false,
  'account': null,
  'linked_at': null,
  'photo': null,
  'permissions': [
    {'key': 'chat', 'available': false, 'on': false},
  ],
};

Map<String, dynamic> _initials(String letters, String color) => {
  'kind': 'initials',
  'photo_url': null,
  'icon_code': null,
  'initials': letters,
  'colors': [color],
  'border': null,
};

Map<String, dynamic> _photoAvatar() => {
  'kind': 'photo',
  'photo_url': '/api/v1/avatars/a1?v=2',
  'icon_code': {
    'icon': 'face',
    'bgColors': ['#5AA9F0'],
  },
  'initials': 'P',
  'colors': ['#E8A33D', '#F06292'],
  'border': {
    'style': 'thin',
    'colors': ['#F06292'],
  },
};

/// GET /users/me after 0.4.2 1b (no top-level icon_code).
Map<String, dynamic> _profile() => {
  'id': 'u1',
  'username': 'nong',
  'display_name': 'Pond',
  'email': null,
  'currency': 'THB',
  'avatar': _photoAvatar(),
  'avatar_settings': {
    'source': 'telegram',
    'colors': ['#E8A33D'],
    'border': {
      'style': 'thin',
      'colors': ['#F06292'],
    },
  },
  'has_password': false,
  'preferences': <String, dynamic>{},
};

void main() {
  late _Adapter adapter;
  late ConnectionsRepository repo;
  late UsersRepository users;

  setUp(() {
    adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
      ..httpClientAdapter = adapter;
    repo = ConnectionsRepository(client: _FakeApi(dio));
    users = UsersRepository(client: _FakeApi(dio));
  });

  group('connection model', () {
    test('the spec example parses', () {
      final c = Connection.fromJson(_telegram());
      expect(c.provider, ConnectionProvider.telegram);
      expect(c.brand, IconCode.hexToColor('#26A5E4'));
      expect(c.logoUrl, endsWith('?v=1'));
      expect(c.available && c.linked, isTrue);
      expect(c.account, '@nong');
      expect(c.linkedAt, DateTime.utc(2026, 10, 28, 9));
      expect(c.photo!.source, 'telegram');
      expect(c.photo!.importedAt, DateTime.utc(2026, 10, 28, 9, 1));
      expect(c.permissions.map((p) => p.key), [
        'chat',
        'ask',
        'slip',
        'notify',
      ]);
      expect(c.permission('chat')!.on, isTrue);
      expect(c.permission('ask')!.available, isFalse);
      expect(c.permission('sheets'), isNull);
    });

    test('an unavailable, unlinked row; a bad brand colour → null', () {
      final c = Connection.fromJson(_line());
      expect(c.available, isFalse);
      expect(c.linked, isFalse);
      expect(c.account, isNull);
      expect(c.linkedAt, isNull);
      expect(c.photo, isNull);
      expect(
        Connection.fromJson({..._line(), 'brand_color': 'green'}).brand,
        isNull,
      );
    });
  });

  group('ConnectionsRepository', () {
    test('list: GET /connections → rows in order', () async {
      adapter.body = {
        'data': [_telegram(), _line()],
        'count': 2,
      };
      final rows = await repo.list();
      expect(adapter.last!.method, 'GET');
      expect(adapter.last!.path, '/connections');
      expect(rows.map((r) => r.provider), ['telegram', 'line']);
    });

    test('one call per button, each answering the row', () async {
      adapter.body = _telegram();
      await repo.get('telegram');
      expect(
        (adapter.last!.method, adapter.last!.path),
        ('GET', '/connections/telegram'),
      );
      await repo.setPermissions('telegram', {'chat': false});
      expect(
        (adapter.last!.method, adapter.last!.path),
        ('PATCH', '/connections/telegram/permissions'),
      );
      expect(adapter.last!.data, {'chat': false});
      await repo.importPhoto('telegram');
      expect(
        (adapter.last!.method, adapter.last!.path),
        ('POST', '/connections/telegram/photo'),
      );
      adapter.body = {..._telegram(), 'linked': false, 'account': null};
      final row = await repo.unlink('telegram');
      expect(
        (adapter.last!.method, adapter.last!.path),
        ('DELETE', '/connections/telegram'),
      );
      expect(row.linked, isFalse);
    });

    test('startLink: the URL to open', () async {
      adapter.body = {
        'url': 'https://t.me/chubiPocket_bot?start=abc',
        'expires_at': '2026-10-28T09:10:00Z',
      };
      final s = await repo.startLink('telegram');
      expect(adapter.last!.path, '/connections/telegram/link');
      expect(s.url, startsWith('https://t.me/'));
      expect(s.expiresAt, DateTime.utc(2026, 10, 28, 9, 10));
    });

    test('deleteAvatar: DELETE /avatars/{source} answers my profile', () async {
      adapter.body = {
        ..._profile(),
        'avatar': _initials('P', '#64B5F6'),
        'avatar_settings': {'source': 'icon', 'colors': [], 'border': null},
      };
      final me = await repo.deleteAvatar('telegram');
      expect(
        (adapter.last!.method, adapter.last!.path),
        ('DELETE', '/avatars/telegram'),
      );
      expect(me.avatar.kind, AvatarKind.initials);
      expect(me.avatarSettings!.isIcon, isTrue);
    });

    test('an error carries the BE code (409 LAST_LOGIN_METHOD)', () async {
      adapter
        ..status = 409
        ..body = {
          'error': {
            'code': ConnectionErrors.lastLoginMethod,
            'message': 'set a password first',
          },
        };
      await expectLater(
        repo.unlink('telegram'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'LAST_LOGIN_METHOD')
              .having((e) => e.statusCode, 'status', 409),
        ),
      );
    });
  });

  group('users/me', () {
    test('avatar, avatar_settings and has_password parse', () {
      final me = User.fromJson(_profile());
      expect(me.avatar.kind, AvatarKind.photo);
      expect(me.iconCode!.icon, 'face'); // the icon = avatar.icon_code
      expect(me.avatarSettings!.source, AvatarSource.telegram);
      expect(me.avatarSettings!.colors, ['#E8A33D']);
      expect(me.avatarSettings!.border!.style, 'thin');
      expect(me.hasPassword, isFalse);
      // An old answer: has_password missing = true, no settings.
      final old = User.fromJson({
        ..._profile(),
        'avatar': null,
        'avatar_settings': null,
        'has_password': null,
      });
      expect(old.hasPassword, isTrue);
      expect(old.avatarSettings, isNull);
      expect(old.avatar.initials, 'P');
    });

    test('an icon edit keeps a photo avatar a photo', () {
      final me = User.fromJson(_profile());
      const code = IconCode(icon: 'star', bgColors: ['#123456']);
      final next = me.copyWith(iconCode: code);
      expect(next.iconCode, code);
      expect(next.avatar.kind, AvatarKind.photo);
      expect(next.avatar.iconCode, code);
    });

    test('PUT /users/me sends avatar_settings', () async {
      adapter.body = _profile();
      await users.setAvatarSettings(
        const AvatarSettings(
          source: AvatarSource.telegram,
          colors: ['#E8A33D', '#F06292'],
          border: AvatarBorder(style: 'dashed', colors: ['#F06292']),
        ),
      );
      expect((adapter.last!.method, adapter.last!.path), ('PUT', '/users/me'));
      expect(adapter.last!.data, {
        'avatar_settings': {
          'source': 'telegram',
          'colors': ['#E8A33D', '#F06292'],
          'border': {
            'style': 'dashed',
            'colors': ['#F06292'],
          },
        },
      });
    });
  });

  group('person payloads read avatar (no top-level icon_code)', () {
    test('contact: own avatar + linked user', () {
      final c = Contact.fromJson({
        'id': 'c1',
        'name': 'Lee',
        'display_name': 'Lee',
        'status': 'active',
        'avatar': _photoAvatar(),
        'linked_user': {
          'id': 'u9',
          'display_name': 'Lee',
          'avatar': _initials('L', '#64B5F6'),
        },
      });
      expect(c.avatar.kind, AvatarKind.photo);
      expect(c.iconCode!.icon, 'face');
      expect(c.linkedUser!.avatar.colors, ['#64B5F6']);
    });

    test('PersonRef / MemberRef / EventMember / AccountMember / UserRef', () {
      final person = EmbeddedPerson.fromJson({
        'name': 'Beam',
        'contact_id': null,
        'avatar': _initials('B', '#64B5F6'),
        'linked': false,
        'linked_user_id': null,
      });
      expect(person.avatar.initials, 'B');
      expect(person.iconCode, isNull);

      final member = BillMemberRef.fromJson({
        'id': 'm1',
        'name': 'Pond',
        'user_id': 'u1',
        'avatar': _photoAvatar(),
        'is_me': true,
      });
      expect(member.avatar.hasPhoto, isTrue);
      expect(member.iconCode!.icon, 'face');

      final ev = ProjectMember.fromJson({
        'id': 'em1',
        'user_id': null,
        'name': 'Mom',
        'avatar': _initials('M', '#F06292'),
        'is_me': false,
        'role': 'member',
        'status': 'active',
      });
      expect(ev.avatar.colors, ['#F06292']);
      expect(
        ProjectMemberRef.tryParse({
          'id': 'em1',
          'name': 'Mom',
          'avatar': _initials('M', '#F06292'),
        })!.avatar.initials,
        'M',
      );

      final w = WalletMember.fromJson({
        'id': 'wm1',
        'user_id': 'u2',
        'name': 'Dao',
        'role': 'member',
        'avatar': _initials('D', '#AED581'),
      });
      expect(w.avatar.colors, ['#AED581']);

      final actor = NotificationActor.fromJson({
        'user_id': 'u3',
        'display_name': 'Aom',
        'avatar': _photoAvatar(),
      });
      expect(actor.avatar.kind, AvatarKind.photo);
    });
  });
}
