import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three detail-page extras fe-budget needed in the kit: a tab bar under
/// the hero, an extra neutral ManageSection action, a multi-chip pick value.
void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => AppUiConfig(child: child!),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('DetailPageBody.tabBar sits under the hero, above sections', (
    t,
  ) async {
    await pump(
      t,
      SizedBox(
        height: 700,
        child: DetailPageBody(
          hero: const Text('HERO'),
          tabBar: PpForgeTabBar<int>(
            tabs: const [
              PpForgeTab(value: 0, label: 'Periods'),
              PpForgeTab(value: 1, label: 'Items'),
            ],
            selected: 0,
            onChanged: (_) {},
          ),
          sections: [
            (first) => SectionCard(
              first: first,
              children: const [DetailRow(label: 'Row')],
            ),
          ],
        ),
      ),
    );
    final hero = t.getTopLeft(find.text('HERO')).dy;
    final tabs = t.getTopLeft(find.text('Periods')).dy;
    final row = t.getTopLeft(find.text('Row')).dy;
    expect(hero, lessThan(tabs));
    expect(tabs, lessThan(row));
  });

  testWidgets('ManageSection.extraActions: neutral button above archive', (
    t,
  ) async {
    var closed = 0;
    await pump(
      t,
      ManageSection(
        first: true,
        extraActions: [
          ManageAction(
            label: 'Close budget',
            icon: PpForgeIcons.success,
            onTap: () => closed++,
          ),
        ],
        archiveLabel: 'Archive',
        onArchive: () {},
      ),
    );
    expect(
      t.getTopLeft(find.text('Close budget')).dy,
      lessThan(t.getTopLeft(find.text('Archive')).dy),
    );
    await t.tap(find.text('Close budget'));
    expect(closed, 1);
  });

  testWidgets('ManageSection with only an extra action is valid', (t) async {
    await pump(
      t,
      ManageSection(
        extraActions: [
          ManageAction(
            label: 'Close',
            icon: PpForgeIcons.success,
            onTap: () {},
          ),
        ],
      ),
    );
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('DetailRow.pick(valueChips:) shows every chip', (t) async {
    await pump(
      t,
      DetailRow.pick(
        label: 'Categories',
        emptyText: 'None',
        valueChips: const [
          PpForgeChip(label: 'Food', selected: true),
          PpForgeChip(label: 'Travel', selected: true),
          PpForgeChip(label: 'Home', selected: true),
        ],
        onTap: () {},
      ),
    );
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('None'), findsNothing);
  });

  testWidgets('DetailRow.pick: empty valueChips falls back to the empty text', (
    t,
  ) async {
    await pump(
      t,
      DetailRow.pick(
        label: 'Categories',
        emptyText: 'None',
        valueChips: const [],
        onTap: () {},
      ),
    );
    expect(find.text('None'), findsOneWidget);
  });
}
