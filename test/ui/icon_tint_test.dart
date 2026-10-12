import 'package:chubi_pocket/ui/domain/icons/icon_code.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/theme_registry.dart';
import 'package:chubi_pocket/ui/tokens/color_contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final palette = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);
  test('tintFor: first bg colour, else first icon colour, else fallback', () {
    final bg = IconCode(
      bgColors: ['#FF0000', '#00FF00'],
      iconColors: ['#0000FF'],
    );
    expect(bg.tintFor(palette), const Color(0xFFFF0000)); // first stop only
    const icon = IconCode(iconColors: ['#0000FF']);
    expect(icon.tintFor(palette), const Color(0xFF0000FF));
    const none = IconCode();
    expect(none.tintFor(palette, fallback: Colors.teal), Colors.teal);
    IconCode? missing;
    expect(missing.tintFor(palette), palette.primary);
  });

  test(
    'ensureContrast: pale colours darken on light, pass-through if fine',
    () {
      const pale = Color(0xFFFFF59D);
      final fixed = ensureContrast(pale, Colors.white);
      expect(fixed.computeLuminance(), lessThan(pale.computeLuminance()));
      expect(
        ensureContrast(const Color(0xFF1A237E), Colors.white),
        const Color(0xFF1A237E),
      );
    },
  );
}
