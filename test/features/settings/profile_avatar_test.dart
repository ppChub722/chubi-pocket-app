import 'package:chubi_pocket/features/settings/presentation/profile_avatar.dart';
import 'package:chubi_pocket/features/users/domain/avatar_settings.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const icon = IconCode(
    icon: 'person',
    background: 'solid',
    bgColors: ['#5AA9F0'],
  );
  const url = '/api/v1/avatars/abc?v=2';

  group('profilePreviewAvatar', () {
    test('icon source → the icon with its colours', () {
      final a = profilePreviewAvatar(
        name: 'ppond',
        iconCode: icon,
        settings: const AvatarSettings(),
        photoUrl: url,
      );
      expect(a.kind, AvatarKind.icon);
      expect(a.colors, ['#5AA9F0']);
    });

    test('photo source: picked colours, then the ring\'s, its ring', () {
      final a = profilePreviewAvatar(
        name: 'ppond',
        iconCode: icon,
        settings: const AvatarSettings(
          source: AvatarSource.telegram,
          colors: ['#E8A33D'],
          border: AvatarBorder(style: 'thick', colors: ['#F06292']),
        ),
        photoUrl: url,
      );
      expect(a.kind, AvatarKind.photo);
      expect(a.photoUrl, url);
      expect(a.iconCode, icon, reason: 'the load-error fallback');
      expect(a.colors, ['#E8A33D', '#F06292']);
      expect(a.border?.style, 'thick');
    });

    test('photo source, no colours → the icon\'s (the BE order)', () {
      final a = profilePreviewAvatar(
        name: 'ppond',
        iconCode: icon,
        settings: const AvatarSettings(source: AvatarSource.telegram),
        photoUrl: url,
      );
      expect(a.colors, ['#5AA9F0']);
      final bare = profilePreviewAvatar(
        name: 'ppond',
        iconCode: null,
        settings: const AvatarSettings(source: AvatarSource.telegram),
        photoUrl: url,
      );
      expect(bare.colors, [AvatarData.nameColorHex('ppond')]);
    });

    test('photo source with no stored picture → the icon', () {
      final a = profilePreviewAvatar(
        name: 'ppond',
        iconCode: null,
        settings: const AvatarSettings(source: AvatarSource.telegram),
      );
      expect(a.kind, AvatarKind.initials);
      expect(a.initials, 'P');
    });
  });

  group('avatar_settings building', () {
    test('withColorsDraft: colours compacted, ring set / cleared', () {
      const s = AvatarSettings(
        source: AvatarSource.telegram,
        colors: ['#111111'],
      );
      final d = AvatarColorsDraft.from(
        s.colors,
        s.border,
      ).withSlot(2, '#333333').withBorderStyle(AvatarBorderStyle.dashed);
      final out = withColorsDraft(s, d);
      expect(out.source, AvatarSource.telegram);
      expect(out.colors, ['#111111', '#333333']);
      expect(
        out.border,
        const AvatarBorder(style: 'dashed', colors: ['#111111']),
      );
      expect(out.toJson()['border'], {
        'style': 'dashed',
        'colors': ['#111111'],
      });
      final none = withColorsDraft(
        out,
        d.withBorderStyle(AvatarBorderStyle.none),
      );
      expect(none.border, isNull);
      expect(none.toJson()['border'], isNull);
    });

    test('avatarSettingsChange: null when the pick did not change', () {
      const a = AvatarSettings(source: AvatarSource.telegram);
      expect(avatarSettingsChange(a, a), isNull);
      expect(
        avatarSettingsChange(a, a.copyWith(source: AvatarSource.icon)),
        const AvatarSettings(),
      );
    });
  });
}
