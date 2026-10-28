import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_geometry_harness.dart';

/// A badge only overlays the leading's corner (owner 2026-10-28): with or
/// without one, the DRAWN leading (the icon glyph, the logo image, the
/// avatar circle and its letters) keeps its size and place, and so do the
/// title and the row's height; for an icon, a logo and an avatar, in both
/// densities. Rows that share a leadingSize slot line up whatever they show.
void main() {
  const rowKey = Key('row');
  const leadingKey = Key('leading');
  const logoKey = Key('logo-paint');

  Widget logo() => const SizedBox.square(
    key: leadingKey,
    dimension: 28,
    child: ColoredBox(key: logoKey, color: Color(0xFF229ED9)),
  );

  /// What is painted inside the leading: every glyph's text box (icons and
  /// initials draw as text), the logo's colour box, the leading box.
  List<Rect> drawn(WidgetTester t) => [
    t.getRect(find.byKey(leadingKey)),
    for (final e
        in find
            .descendant(
              of: find.byKey(leadingKey),
              matching: find.byType(RichText),
            )
            .evaluate())
      t.getRect(find.byWidget(e.widget)),
    for (final e
        in find
            .descendant(
              of: find.byKey(leadingKey),
              matching: find.byType(ColoredBox),
            )
            .evaluate())
      t.getRect(find.byWidget(e.widget)),
  ];

  List<double> glyphSizes(WidgetTester t) => [
    for (final e
        in find
            .descendant(
              of: find.byKey(leadingKey),
              matching: find.byType(RichText),
            )
            .evaluate())
      (e.renderObject! as RenderParagraph).text.style?.fontSize ?? 0,
  ];

  final leadings = <String, (Widget Function(AppRowDensity), double?)>{
    'icon': (
      (d) => d == AppRowDensity.detail
          ? const AppIcon(AppIcons.link, key: leadingKey)
          : const IconTile(
              key: leadingKey,
              icon: AppIcons.link,
              color: Color(0xFF229ED9),
            ),
      null,
    ),
    'icon in a slot': (
      (d) => d == AppRowDensity.detail
          ? const AppIcon(AppIcons.link, key: leadingKey)
          : const IconTile(
              key: leadingKey,
              icon: AppIcons.link,
              color: Color(0xFF229ED9),
            ),
      40,
    ),
    'logo': ((_) => logo(), 32),
    'avatar': (
      (_) => const UserAvatar(key: leadingKey, displayName: 'Pond', size: 32),
      32,
    ),
  };

  Widget row(AppRowDensity d, Widget leading, double? size, RowBadge? b) =>
      SectionCard(
        first: true,
        children: [
          AppRow(
            key: rowKey,
            density: d,
            leading: leading,
            leadingSize: size,
            badge: b,
            title: const Text('Title'),
            trailing: const Text('Value'),
          ),
        ],
      );

  for (final density in AppRowDensity.values) {
    for (final MapEntry(key: kind, value: (leading, size))
        in leadings.entries) {
      for (final badge in const [
        RowBadge(icon: AppIcons.check),
        RowBadge.logo(ColoredBox(color: Color(0xFF06C755))),
      ]) {
        testWidgets(
          '${density.name} $kind: a ${badge.icon == null ? 'logo' : 'icon'} '
          'badge moves and resizes nothing',
          (t) async {
            addTearDown(t.view.reset);
            Future<List<Object>> measure(RowBadge? b) async {
              await pumpGeometryRow(
                t,
                row(density, leading(density), size, b),
                width: 420,
                scale: 1,
              );
              return [
                ...drawn(t),
                ...glyphSizes(t),
                t.getRect(find.text('Title')),
                t.getRect(find.byKey(rowKey)),
              ];
            }

            final plain = await measure(null);
            final badged = await measure(badge);
            expect(badged, plain);
            expect(find.byType(CornerBadge), findsOneWidget);
          },
        );
      }
    }
  }

  testWidgets('one slot: logo, avatar + badge and plain avatar line up', (
    t,
  ) async {
    addTearDown(t.view.reset);
    await pumpGeometryRow(
      t,
      SectionCard(
        first: true,
        children: [
          AppDetailRow(
            key: const Key('a'),
            leading: const UserAvatar(displayName: 'Pond', size: 32),
            leadingSize: 32,
            badge: const RowBadge.logo(ColoredBox(color: Color(0xFF229ED9))),
            label: 'Linked',
          ),
          const AppDetailRow(
            key: Key('b'),
            leading: SizedBox.square(
              dimension: 32,
              child: ColoredBox(color: Color(0xFF229ED9)),
            ),
            leadingSize: 32,
            label: 'Logo',
          ),
          const AppDetailRow(
            key: Key('c'),
            leading: UserAvatar(displayName: 'Pond', size: 32),
            leadingSize: 32,
            label: 'Plain',
          ),
        ],
      ),
      width: 420,
      scale: 1,
    );
    double height(String k) => t.getRect(find.byKey(Key(k))).height;
    expect(height('a'), height('b'));
    expect(height('a'), height('c'));
    for (final l in ['Logo', 'Plain']) {
      expect(t.getRect(find.text(l)).left, t.getRect(find.text('Linked')).left);
    }
  });

  testWidgets('IconTile and a badged avatar draw the same glyph', (t) async {
    addTearDown(t.view.reset);
    Future<List<Object>> tile(IconData? badge) async {
      await pumpGeometryRow(
        t,
        Center(
          child: IconTile(
            key: leadingKey,
            icon: AppIcons.link,
            color: const Color(0xFF229ED9),
            size: 40,
            badgeIcon: badge,
          ),
        ),
        width: 420,
        scale: 1,
      );
      return [...drawn(t).take(2), ...glyphSizes(t).take(1)];
    }

    expect(await tile(AppIcons.check), await tile(null));
  });
}
