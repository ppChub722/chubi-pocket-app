import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// HeroHeader(fill:) = a list hero's head in ONE row: [tile] [stepper, fills]
/// [🔍], all as tall as the module tile and centred on one axis.
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Future<void> pump(WidgetTester t, {bool foldable = false}) async {
    t.view.physicalSize = const Size(390, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final open = ValueNotifier(true);
    addTearDown(open.dispose);
    final header = HeroHeader(
      leading: const [HeroModuleTile(AppIcons.transactions)],
      fill: StepperPill(
        label: 'October 2026',
        onPrev: () {},
        onNext: () {},
        onTap: () {},
      ),
      actions: [CardActionButton(icon: AppIcons.search, onTap: () {})],
    );
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: AppHeroCard(
            style: const HeroStyle.plain(),
            margin: const EdgeInsets.all(16),
            open: foldable ? open : null,
            header: header,
            content: const [Text('content')],
            folded: foldable ? const [Text('folded')] : null,
          ),
        ),
      ),
    );
  }

  Rect rectOf(WidgetTester t, Finder f) => t.getRect(f);

  testWidgets('tile, stepper and 🔍 are 40 high and share one centre line', (
    t,
  ) async {
    await pump(t);
    final tile = rectOf(t, find.byType(HeroModuleTile));
    final pill = rectOf(t, find.byType(StepperPill));
    final search = rectOf(t, find.byType(CardActionButton));
    for (final r in [tile, pill, search]) {
      expect(r.height, HeroModuleTile.size);
      expect(r.center.dy, closeTo(tile.center.dy, 0.01));
    }
    expect(search.width, HeroModuleTile.size);
  });

  testWidgets('the stepper fills the row between the tile and 🔍', (t) async {
    await pump(t);
    final gap = HeroMetrics.of(t.element(find.byType(StepperPill))).itemGap;
    final tile = rectOf(t, find.byType(HeroModuleTile));
    final pill = rectOf(t, find.byType(StepperPill));
    final search = rectOf(t, find.byType(CardActionButton));
    final row = rectOf(
      t,
      find
          .ancestor(of: find.byType(StepperPill), matching: find.byType(Row))
          .first,
    );
    expect(pill.width, row.width - tile.width - search.width - 2 * gap);
    expect(tile.left, row.left);
    expect(search.right, row.right);
    // ‹ and › sit at the pill's ends, the label in between.
    final prev = rectOf(t, find.byIcon(AppIcons.chevronLeft));
    final next = rectOf(t, find.byIcon(AppIcons.chevronRight));
    final label = rectOf(t, find.text('October 2026'));
    expect(prev.center.dx - pill.left, lessThan(HeroModuleTile.size));
    expect(pill.right - next.center.dx, lessThan(HeroModuleTile.size));
    expect(label.left, greaterThan(prev.right));
    expect(label.right, lessThan(next.left));
  });

  testWidgets('a foldable card keeps ⌃ in the corner, outside the row', (
    t,
  ) async {
    await pump(t, foldable: true);
    final tile = rectOf(t, find.byType(HeroModuleTile));
    final pill = rectOf(t, find.byType(StepperPill));
    final search = rectOf(t, find.byType(CardActionButton));
    final fold = rectOf(t, find.byType(AppHeroFoldButton));
    expect(pill.center.dy, closeTo(tile.center.dy, 0.01));
    expect(search.center.dy, closeTo(tile.center.dy, 0.01));
    // Tucked into the corner: above the row's centre, right of the 🔍.
    expect(fold.center.dy, lessThan(tile.center.dy));
    expect(fold.left, greaterThanOrEqualTo(search.right));
  });

  testWidgets('in a tinted hero the pill and the bars take the card colors', (
    t,
  ) async {
    const teal = Color(0xFF00897B);
    Widget bars() => const DailyBars(
      bars: [
        DailyBar(value: 10),
        DailyBar(value: 20, kind: DailyBarKind.today),
        DailyBar(value: 0, kind: DailyBarKind.future),
      ],
    );
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: Column(
            children: [
              AppHeroCard(
                style: const HeroStyle.tinted(color: teal),
                header: HeroHeader(
                  leading: const [HeroModuleTile(AppIcons.transactions)],
                  fill: StepperPill(label: 'October 2026', onPrev: () {}),
                ),
                content: [bars()],
              ),
              // Outside a hero: the old look.
              StepperPill(label: 'Alone', onPrev: () {}),
              bars(),
            ],
          ),
        ),
      ),
    );
    final hero = HeroColors.maybeOf(t.element(find.byType(StepperPill).first))!;
    Material pill(int i) => t.widget<Material>(
      find
          .descendant(
            of: find.byType(StepperPill).at(i),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(pill(0).color, hero.soft);
    expect(pill(0).elevation, 0);
    expect(pill(1).color, isNot(hero.soft));
    expect(pill(1).elevation, greaterThan(0));
    Color bar(int list, int i) =>
        (t
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(DailyBars).at(list),
                            matching: find.byType(DecoratedBox),
                          )
                          .at(i),
                    )
                    .decoration
                as BoxDecoration)
            .color!;
    expect(bar(0, 1), hero.accent); // today
    expect(bar(0, 2), hero.track); // future
    final palette = Theme.of(
      t.element(find.byType(DailyBars).last),
    ).extension<AppColors>()!;
    expect(bar(1, 1), palette.expense);
  });

  testWidgets('only the list head is 40: other hero heads keep control 36', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: AppHeroCard(
            style: const HeroStyle.plain(),
            header: HeroHeader(
              leading: [StepperPill(label: 'Oct', onPrev: () {})],
              actions: [CardActionButton(icon: AppIcons.search, onTap: () {})],
            ),
            content: const [Text('content')],
          ),
        ),
      ),
    );
    expect(
      t.getSize(find.byType(StepperPill)).height,
      ControlSizes.fallback.control,
    );
    expect(
      t.getSize(find.byType(CardActionButton)).height,
      ControlSizes.fallback.control,
    );
  });
}
