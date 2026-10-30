import 'package:chubi_pocket/features/connections/data/connections_repository.dart';
import 'package:chubi_pocket/features/connections/domain/connection.dart';
import 'package:chubi_pocket/features/connections/presentation/connection_view.dart';
import 'package:chubi_pocket/features/connections/presentation/cubit/connections_cubit.dart';
import 'package:chubi_pocket/features/users/domain/avatar_settings.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements ConnectionsRepository {}

/// Rows shaped like GET /connections (0.4.2 1b).
Connection _row(
  String provider, {
  bool available = true,
  bool linked = false,
  bool photo = false,
  List<Map<String, dynamic>> permissions = const [],
}) => Connection.fromJson({
  'provider': provider,
  'name': provider.toUpperCase(),
  'brand_color': '#26A5E4',
  'logo_url': '/api/v1/brand-logos/$provider.png?v=1',
  'available': available,
  'linked': linked,
  'account': linked ? '@nong' : null,
  'linked_at': linked ? '2026-10-28T09:00:00Z' : null,
  'photo': photo
      ? {
          'source': provider,
          'url': '/api/v1/avatars/abc?v=2',
          'imported_at': '2026-10-28T09:01:00Z',
        }
      : null,
  'permissions': permissions,
});

void main() {
  group('connection row state', () {
    test('available false → coming soon, even when linked', () {
      expect(
        connectionRowState(_row('line', available: false)),
        ConnectionRowState.comingSoon,
      );
      expect(
        connectionRowState(_row('line', available: false, linked: true)),
        ConnectionRowState.comingSoon,
      );
    });

    test('not linked → grey (a kept picture does not matter)', () {
      expect(
        connectionRowState(_row('telegram', photo: true)),
        ConnectionRowState.unlinked,
      );
    });

    test('linked → picture + badge, else the logo', () {
      expect(
        connectionRowState(_row('telegram', linked: true, photo: true)),
        ConnectionRowState.linkedPhoto,
      );
      expect(
        connectionRowState(_row('telegram', linked: true)),
        ConnectionRowState.linkedLogo,
      );
    });
  });

  group('settings card + profile helpers', () {
    final items = [
      _row('telegram', linked: true, photo: true),
      _row('line', available: false),
      _row('google', linked: true),
    ];

    test('linkedLogos: linked apps only, in order', () {
      expect(linkedLogos(items), [
        ('/api/v1/brand-logos/telegram.png?v=1', 'TELEGRAM'),
        ('/api/v1/brand-logos/google.png?v=1', 'GOOGLE'),
      ]);
      expect(linkedLogos(const []), isEmpty);
    });

    test('pictureSourceApp: the linked app of the picked source', () {
      expect(
        pictureSourceApp(
          const AvatarSettings(source: AvatarSource.telegram),
          items,
        )?.provider,
        'telegram',
      );
      expect(pictureSourceApp(const AvatarSettings(), items), isNull);
      expect(
        pictureSourceApp(
          const AvatarSettings(source: AvatarSource.upload),
          items,
        ),
        isNull,
      );
      expect(
        pictureSourceApp(const AvatarSettings(source: AvatarSource.telegram), [
          _row('telegram', photo: true),
        ]),
        isNull,
        reason: 'unlinked: the BE falls back to the icon, no badge',
      );
      expect(pictureSourceApp(null, items), isNull);
    });

    test('photoSourceApps: linked apps with a stored picture', () {
      expect(photoSourceApps(items).map((c) => c.provider), ['telegram']);
      expect(photoSourceApps([_row('telegram', photo: true)]), isEmpty);
    });

    test('permission rows: switch / dimmed / coming soon', () {
      final c = _row(
        'telegram',
        linked: true,
        permissions: [
          {'key': 'chat', 'available': true, 'on': true},
          {'key': 'ask', 'available': false, 'on': false},
        ],
      );
      expect(
        permissionRowState(c, c.permissions[0]),
        PermissionRowState.toggle,
      );
      expect(
        permissionRowState(c, c.permissions[1]),
        PermissionRowState.comingSoon,
      );
      final off = _row(
        'telegram',
        permissions: [
          {'key': 'chat', 'available': true, 'on': false},
        ],
      );
      expect(
        permissionRowState(off, off.permissions[0]),
        PermissionRowState.dimmed,
      );
    });
  });

  group('ConnectionsCubit', () {
    test('load fills the rows; a failure keeps them with the error', () async {
      final repo = _Repo();
      final cubit = ConnectionsCubit(repository: repo);
      when(repo.list).thenAnswer((_) async => [_row('telegram')]);
      await cubit.load();
      expect(cubit.state.items!.single.provider, 'telegram');
      when(repo.list).thenThrow(StateError('offline'));
      await cubit.load();
      expect(cubit.state.items!.single.provider, 'telegram');
      expect(cubit.state.error, isA<StateError>());
      expect(cubit.state.loading, isFalse);
    });

    test('ensureLoaded calls once', () async {
      final repo = _Repo();
      final cubit = ConnectionsCubit(repository: repo);
      when(repo.list).thenAnswer((_) async => [_row('telegram')]);
      await cubit.ensureLoaded();
      await cubit.ensureLoaded();
      verify(repo.list).called(1);
    });

    test('put replaces one row; photoDeleted drops its picture', () async {
      final repo = _Repo();
      final cubit = ConnectionsCubit(repository: repo);
      when(repo.list).thenAnswer((_) async => [_row('telegram'), _row('line')]);
      await cubit.load();
      cubit.put(_row('telegram', linked: true, photo: true));
      expect(cubit.state.items!.map((c) => c.provider), ['telegram', 'line']);
      expect(cubit.state.of('telegram')!.linked, isTrue);
      cubit.photoDeleted('telegram');
      final t = cubit.state.of('telegram')!;
      expect(t.photo, isNull);
      expect(t.linked, isTrue);
      expect(t.account, '@nong');
      cubit.clear();
      expect(cubit.state.items, isNull);
    });
  });
}
