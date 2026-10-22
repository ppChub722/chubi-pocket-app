import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// HeroChipRow: the chip row at the bottom of a hero — every chip CHIP size
/// (28) whatever it asks for, wraps, never overflows (owner 2026-10-21).
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Future<void> pump(WidgetTester t, double width) async {
    t.view.physicalSize = Size(width, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: AppHeroCard(
            style: const HeroStyle.plain(),
            content: [
              HeroChipRow(
                chips: [
                  // The recurring detail mix: a status dropdown, a kind
                  // pill, a control-size chip, a mini (event) chip, a
                  // member chip, a category path, and a very long label.
                  StatusChip(
                    key: const ValueKey('status'),
                    label: 'Active',
                    kind: StatusKind.active,
                    onTap: () {},
                  ),
                  const AppChip(
                    key: ValueKey('kind'),
                    label: 'Subscription',
                    selected: true,
                    tone: AppChipTone.neutral,
                  ),
                  const AppChip(
                    key: ValueKey('control'),
                    label: 'Transportation',
                    icon: AppIcons.category,
                    size: ChipSize.control,
                  ),
                  const AppChip(
                    key: ValueKey('mini'),
                    label: 'sfaf',
                    icon: AppIcons.tag,
                    selected: true,
                    tone: AppChipTone.danger,
                    size: ChipSize.mini,
                  ),
                  const ChipPath(
                    key: ValueKey('path'),
                    segments: [
                      ChipPathSegment(label: 'Food', icon: AppIcons.category),
                      ChipPathSegment(label: 'Snacks', icon: AppIcons.category),
                    ],
                  ),
                  const AppChip(
                    key: ValueKey('long'),
                    label:
                        'A very long chip label that cannot fit on one line '
                        'of a phone-wide hero card at all',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  for (final width in [412.0, 320.0]) {
    testWidgets('width $width: every chip is 28 high, no overflow', (t) async {
      await pump(t, width);
      expect(t.takeException(), isNull);
      final chips = find.descendant(
        of: find.byType(HeroChipRow),
        matching: find.byType(AppChip),
      );
      expect(chips, findsAtLeastNWidgets(7)); // the path has 2
      for (final e in chips.evaluate()) {
        expect(
          t.getSize(find.byWidget(e.widget)).height,
          ControlSizes.fallback.chip,
          reason: (e.widget as AppChip).label,
        );
      }
      // The status dropdown keeps its ▾ and stays tappable.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('status')),
          matching: find.byIcon(AppIcons.dropdown),
        ),
        findsOneWidget,
      );
      // Wraps: the long chip stays inside the card.
      final card = t.getRect(find.byType(AppHeroCard));
      expect(
        t.getRect(find.byKey(const ValueKey('long'))).right,
        lessThanOrEqualTo(card.right),
      );
    });
  }

  testWidgets('outside the row a chip keeps its own size', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: const Scaffold(
          body: Center(
            child: AppChip(label: 'Mini', size: ChipSize.mini),
          ),
        ),
      ),
    );
    expect(t.getSize(find.byType(AppChip)).height, ControlSizes.fallback.mini);
  });
}
