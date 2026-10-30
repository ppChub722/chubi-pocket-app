import 'package:chubi_pocket/ui/tokens/color_contrast.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void main() {
  final palette = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);
  const white = Color(0xFFFFFFFF);

  group('AvatarData', () {
    test('the BE object parses (openapi example, photo + border)', () {
      final a = AvatarData.fromJson({
        'kind': 'photo',
        'photo_url': '/api/v1/avatars/0191c2a0-0000-7000-8000-0000000000cc?v=2',
        'icon_code': {
          'icon': 'face',
          'bgColors': ['#5AA9F0'],
        },
        'initials': 'P',
        'colors': ['#E8A33D', '#F06292'],
        'border': {
          'style': 'solid',
          'colors': ['#F06292'],
        },
      });
      expect(a.kind, AvatarKind.photo);
      expect(a.hasPhoto, isTrue);
      expect(a.photoUrl, endsWith('?v=2'));
      expect(a.iconCode!.icon, 'face');
      expect(a.initials, 'P');
      expect(a.colors, ['#E8A33D', '#F06292']);
      expect(a.border!.style, 'solid');
      expect(a.border!.isNone, isFalse);
      expect(AvatarData.fromJson(a.toJson()), a);
    });

    test('initials kind with nulls; an unknown kind reads as initials', () {
      final a = AvatarData.fromJson({
        'kind': 'initials',
        'photo_url': null,
        'icon_code': null,
        'initials': 'B',
        'colors': ['#64B5F6'],
        'border': null,
      });
      expect(a.kind, AvatarKind.initials);
      expect(a.hasPhoto, isFalse);
      expect(a.iconCode, isNull);
      expect(a.border, isNull);
      expect(
        AvatarData.fromJson({'kind': 'hologram'}).kind,
        AvatarKind.initials,
      );
      // A photo kind with no URL can't be drawn as a photo.
      expect(AvatarData.fromJson({'kind': 'photo'}).hasPhoto, isFalse);
    });

    test('parse: `avatar` wins; an old payload builds one from icon_code', () {
      final fresh = AvatarData.parse({
        'name': 'Mom',
        'avatar': {
          'kind': 'initials',
          'initials': 'M',
          'colors': ['#F06292'],
        },
      }, name: 'Mom');
      expect(fresh.colors, ['#F06292']);

      final old = AvatarData.parse({
        'name': 'Aom Chan',
        'icon_code': {
          'icon': 'person',
          'bgColors': ['#26A69A'],
          'iconColors': ['#FFFFFF'],
          'borderColors': ['#26A69A', '#00796B'],
        },
      }, name: 'Aom Chan');
      expect(old.kind, AvatarKind.icon);
      expect(old.initials, 'AC');
      // backgrounds → icons → borders, no repeats.
      expect(old.colors, ['#26A69A', '#FFFFFF', '#00796B']);

      final none = AvatarData.parse({'name': 'Bee'}, name: 'Bee');
      expect(none.kind, AvatarKind.initials);
      expect(none.colors, [AvatarData.nameColorHex('Bee')]);
    });

    test('forName: initials + the name-hash colour (as AppAvatar)', () {
      expect(AvatarData.initialsOf('aom chan  dao'), 'AC');
      expect(AvatarData.initialsOf('  '), '');
      expect(AvatarData.initialsOf('ปอนด์'), 'ป');
      expect(AvatarData.initialsOf('👍🏽 ok'), '👍🏽O');
      for (final n in ['Bee', 'ปอนด์', 'Aom Chan', '']) {
        expect(
          IconCode.hexToColor(AvatarData.nameColorHex(n)),
          AppAvatar.colorFor(n),
        );
      }
      expect(AvatarData.forName('').colors, hasLength(1));
    });

    test('withIcon keeps a photo, re-colours an icon / initials avatar', () {
      final photo = AvatarData.fromJson({
        'kind': 'photo',
        'photo_url': '/api/v1/avatars/x?v=1',
        'initials': 'P',
        'colors': ['#E8A33D'],
      });
      const code = IconCode(icon: 'star', bgColors: ['#123456']);
      final p2 = photo.withIcon(code);
      expect(p2.kind, AvatarKind.photo);
      expect(p2.iconCode, code);
      expect(p2.colors, ['#E8A33D']);

      final i2 = AvatarData.forName('Bee').withIcon(code);
      expect(i2.kind, AvatarKind.icon);
      expect(i2.colors, ['#123456']);
      expect(i2.withIcon(null).kind, AvatarKind.initials);
    });
  });

  group('ServerImageScope.resolveUrl', () {
    const base = 'https://chubipocket-api.ppforge.dev/api/v1';
    test('a server-root path, a relative path, an absolute URL', () {
      expect(
        ServerImageScope.resolveUrl(base, '/api/v1/avatars/a1?v=3').toString(),
        'https://chubipocket-api.ppforge.dev/api/v1/avatars/a1?v=3',
      );
      expect(
        ServerImageScope.resolveUrl(
          base,
          'brand-logos/telegram.png?v=1',
        ).toString(),
        'https://chubipocket-api.ppforge.dev/api/v1/brand-logos/telegram.png?v=1',
      );
      expect(
        ServerImageScope.resolveUrl(
          'http://10.0.2.2:8080/api/v1',
          '/api/v1/avatars/a1?v=3',
        ).toString(),
        'http://10.0.2.2:8080/api/v1/avatars/a1?v=3',
      );
      expect(
        ServerImageScope.resolveUrl(
          base,
          'https://cdn.example/x.png',
        ).toString(),
        'https://cdn.example/x.png',
      );
    });

    test('the image key is the URL (a new ?v= is a new picture)', () {
      Future<Uint8List> fetch(Uri _) async => Uint8List(0);
      final a = ServerImageProvider(Uri.parse('https://h/a?v=1'), fetch);
      final b = ServerImageProvider(Uri.parse('https://h/a?v=1'), fetch);
      final c = ServerImageProvider(Uri.parse('https://h/a?v=2'), fetch);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('ProfileColors', () {
    test('slot n = the nearest set slot below; none → fallback', () {
      Color at(List<String> cs, int n, {Color? fallback}) => ProfileColors.slot(
        cs,
        n,
        palette: palette,
        surface: white,
        fallback: fallback,
      );
      const cs = ['#1A237E', '', '#B71C1C'];
      expect(at(cs, 0), const Color(0xFF1A237E));
      expect(at(cs, 1), const Color(0xFF1A237E)); // slot 2 unset → slot 1
      expect(at(cs, 2), const Color(0xFFB71C1C));
      expect(at(cs, 7), const Color(0xFFB71C1C)); // past the end → last set
      expect(
        at(['', '#1A237E'], 0, fallback: const Color(0xFF004D40)),
        const Color(0xFF004D40),
      );
      expect(at(const [], 0), ensureContrast(palette.primary, white));
    });

    test('every colour passes ensureContrast against the surface', () {
      const pale = '#FFF59D';
      final c = ProfileColors.slot(
        const [pale],
        0,
        palette: palette,
        surface: white,
      );
      expect(_ratio(c, white), greaterThanOrEqualTo(3));
      for (final d in ProfileColors.distinct(
        const [pale],
        4,
        palette: palette,
        surface: white,
      )) {
        expect(_ratio(d, white), greaterThanOrEqualTo(3));
      }
    });

    test('distinct: set colours first (no repeats), then shades', () {
      final out = ProfileColors.distinct(
        const ['#1A237E', '#1A237E', '#B71C1C'],
        4,
        palette: palette,
        surface: white,
      );
      expect(out, hasLength(4));
      expect(out[0], const Color(0xFF1A237E));
      expect(out[1], const Color(0xFFB71C1C));
      expect(out.toSet(), hasLength(4));
      expect(
        ProfileColors.distinct(const [], 2, palette: palette, surface: white),
        hasLength(2),
      );
      expect(
        ProfileColors.distinct(
          const ['#1A237E'],
          0,
          palette: palette,
          surface: white,
        ),
        isEmpty,
      );
    });

    test('a theme token resolves through the palette', () {
      expect(
        ProfileColors.slot(
          const ['@presetThemeColor1'],
          0,
          palette: palette,
          surface: white,
        ),
        ensureContrast(palette.primary, white),
      );
    });
  });
}
