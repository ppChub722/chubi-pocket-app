import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Owner 2026-10-12: the count badge floats OUTSIDE the circle, and the
/// activity states never move the icon or change the button's size.
void main() {
  Future<void> pump(WidgetTester t, PpForgeIconButton b) => t.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: b)),
    ),
  );

  PpForgeIconButton chip({
    IconChipActivity activity = IconChipActivity.none,
    int badge = 0,
  }) => PpForgeIconButton(
    icon: PpForgeIcons.notifications,
    onPressed: () {},
    activity: activity,
    badgeCount: badge,
  );

  testWidgets('size and icon position are the same in every activity state', (
    t,
  ) async {
    await pump(t, chip());
    final size = t.getSize(find.byType(PpForgeIconButton));
    final at = t.getCenter(find.byIcon(PpForgeIcons.notifications));
    for (final a in [IconChipActivity.progress, IconChipActivity.done]) {
      await pump(t, chip(activity: a));
      await t.pump(const Duration(milliseconds: 300));
      expect(
        t.getSize(find.byType(PpForgeIconButton)),
        size,
        reason: '$a size',
      );
      if (a == IconChipActivity.progress) {
        expect(
          t.getCenter(find.byIcon(PpForgeIcons.notifications)),
          at,
          reason: 'progress keeps the icon in place',
        );
      } else {
        // The icon stays in place (dimmed) and the ✓ sits on top of it.
        expect(t.getCenter(find.byIcon(PpForgeIcons.notifications)), at);
        expect(t.getCenter(find.byIcon(PpForgeIcons.check)), at);
        expect(
          t
              .widget<AnimatedOpacity>(
                find.ancestor(
                  of: find.byIcon(PpForgeIcons.notifications),
                  matching: find.byType(AnimatedOpacity),
                ),
              )
              .opacity,
          0.3,
        );
      }
    }
  });

  testWidgets(
    'the badge sits outside the circle (top-right), not over the icon',
    (t) async {
      await pump(t, chip(badge: 7));
      final circle = t.getRect(find.byType(PpForgeIconButton));
      final badge = t.getRect(find.text('7'));
      final icon = t.getRect(find.byIcon(PpForgeIcons.notifications));
      // Half of it past the right / top edge.
      expect(badge.center.dx, greaterThan(circle.right - 8));
      expect(badge.center.dy, lessThan(circle.top + 8));
      expect(badge.overlaps(icon), isFalse);
      // The button's own size is unchanged by the badge.
      await pump(t, chip());
      expect(t.getSize(find.byType(PpForgeIconButton)), circle.size);
    },
  );

  testWidgets('no badge while a job runs; it is back when done', (t) async {
    await pump(t, chip(badge: 3, activity: IconChipActivity.progress));
    expect(find.text('3'), findsNothing);
    await pump(t, chip(badge: 3, activity: IconChipActivity.done));
    expect(find.text('3'), findsOneWidget);
  });
  testWidgets('the badge stays on the button under a tight, wide parent', (
    t,
  ) async {
    t.view.physicalSize = const Size(420 * 3, 800 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            // A stretched column hands the button a TIGHT full width.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [chip(badge: 3)],
          ),
        ),
      ),
    );
    final button = t.getRect(find.byType(PpForgeIconButton).first);
    final badge = t.getRect(find.text('3'));
    final circle = t.getRect(find.byType(Material).last);
    expect(
      badge.center.dx,
      lessThan(circle.right + 12),
      reason: 'badge hangs off the button, not the page edge',
    );
    expect(button.left, lessThan(60));
  });
}
