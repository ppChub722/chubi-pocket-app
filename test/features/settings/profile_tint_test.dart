import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The settings profile card is tinted with the user's avatar colour (the
/// icon colour, else the initials colour) — never a page colour.
void main() {
  final palette = sweetTheme.lightColors;

  test('no icon: the card tint is the initials avatar colour', () {
    for (final name in ['QA Lead', 'Aom Chan', 'Bee', 'ก้อง']) {
      final tint = (null as IconCode?).tintFor(palette, avatarName: name);
      expect(tint, PpForgeAvatar.colorFor(name), reason: name);
    }
  });

  testWidgets('HeaderCard draws the avatar colour as its hero surface', (
    t,
  ) async {
    const name = 'QA Lead';
    final tint = (null as IconCode?).tintFor(palette, avatarName: name);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [palette]),
        home: Scaffold(
          body: HeaderCard(
            accent: tint,
            leading: const UserAvatar(displayName: name, size: 52),
            title: const Text(name),
          ),
        ),
      ),
    );
    final surface = t.widget<HeroSurface>(find.byType(HeroSurface));
    expect(surface.style.color, PpForgeAvatar.colorFor(name));
    expect(surface.style.tinted, isTrue);
  });
}
