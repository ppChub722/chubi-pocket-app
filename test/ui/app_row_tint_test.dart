import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/tokens/color_contrast.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_geometry_harness.dart';

/// AppRow plan step 3: a tinted row's accent stays readable, and a tinted
/// first / last row in a SectionCard keeps the card's round corners.
void main() {
  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  test('a yellow accent on white is darkened to at least 3:1', () {
    const yellow = Color(0xFFFFEB3B);
    const white = Color(0xFFFFFFFF);
    // The raw yellow fails (≈ 1.2:1), so the check has something to fix.
    expect(ratio(yellow, white), lessThan(3));
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: yellow, surface: white),
    );
    final colors = HeroColors.from(theme, yellow);
    expect(ratio(colors.accent, white), greaterThanOrEqualTo(3));
    expect(ensureContrast(yellow, white), colors.accent);
  });

  testWidgets('tinted first / last rows keep the card corners', (t) async {
    addTearDown(t.view.reset);
    const accent = Color(0xFF229ED9);
    const first = Key('first');
    const last = Key('last');
    void noop() {}
    await pumpGeometryRow(
      t,
      SectionCard(
        first: true,
        children: [
          AppDetailRow(
            key: first,
            icon: AppIcons.link,
            label: 'First',
            accent: accent,
            tinted: true,
            onTap: noop,
          ),
          AppDetailRow(
            key: last,
            icon: AppIcons.link,
            label: 'Last',
            accent: accent,
            tinted: true,
            onTap: noop,
          ),
        ],
      ),
      width: 320,
      scale: 1,
    );
    final soft = HeroColors.from(geometryTheme(), accent).soft;
    // 8-bit pixels: within one step per channel of the wash.
    Matcher isSoft() => predicate<Color>(
      (c) =>
          (c.a - soft.a).abs() <= 1 / 255 &&
          (c.r - soft.r).abs() <= 1.5 / 255 &&
          (c.g - soft.g).abs() <= 1.5 / 255 &&
          (c.b - soft.b).abs() <= 1.5 / 255,
      'the soft wash ${GeometrySnap.hex(soft)}',
    );
    final top = t.getRect(find.byKey(first));
    final bottom = t.getRect(find.byKey(last));

    // Inside: the accent's soft wash.
    expect(await samplePixel(t, Offset(top.left + 3, top.center.dy)), isSoft());
    expect(
      await samplePixel(t, Offset(bottom.right - 3, bottom.center.dy)),
      isSoft(),
    );
    // The card's outer corners: nothing painted (the radius is 16 px).
    for (final corner in [
      top.topLeft + const Offset(1, 1),
      top.topRight + const Offset(-2, 1),
      bottom.bottomLeft + const Offset(1, -2),
      bottom.bottomRight + const Offset(-2, -2),
    ]) {
      expect((await samplePixel(t, corner)).a, 0, reason: '$corner');
    }
    // The inner corners (where the rows meet) stay square: filled.
    expect(
      await samplePixel(t, top.bottomLeft + const Offset(1, -2)),
      isSoft(),
    );
    expect(await samplePixel(t, bottom.topLeft + const Offset(1, 1)), isSoft());
  });

  for (final (mode, colors) in [
    ('light', sweetTheme.lightColors),
    ('dark', sweetTheme.darkColors),
  ]) {
    testWidgets('a locked value and its lock use the muted token ($mode)', (
      t,
    ) async {
      final scheme = colors.toColorScheme();
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme, extensions: [colors]),
          home: const Scaffold(
            body: SectionCard(
              first: true,
              children: [
                AppDetailRow(
                  label: 'Username',
                  trailing: Text('ppond', key: Key('value')),
                  locked: true,
                ),
              ],
            ),
          ),
        ),
      );
      final paragraph = t.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(const Key('value')),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraph.text.style?.color, scheme.onSurfaceVariant);
      expect(
        t.widget<Icon>(find.byIcon(AppIcons.lock)).color,
        scheme.onSurfaceVariant,
      );
      expect(scheme.onSurfaceVariant, isNot(scheme.primary));
    });
  }
}
