import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The quick-create "ผูกกับ" kit (owner 2026-10-21): LinkModeBar (label + 4
/// pill tabs on ONE row) and ShareCard rows, at phone widths. Tests draw text
/// in the square test font (the app's Thai font comes from google_fonts at run
/// time), so they check the RULES: nothing overflows, the selected tab's icon
/// never cuts its word, segments are equal, rows line up.
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  const tabs = [
    AppTab(value: 0, label: 'ส่วนตัว', icon: AppIcons.wallet),
    AppTab(value: 1, label: 'แบ่ง', icon: AppIcons.split),
    AppTab(value: 2, label: 'จ่ายแทน', icon: AppIcons.contact),
    AppTab(value: 3, label: 'อีเวนต์', icon: AppIcons.project),
  ];

  Future<void> pumpBar(WidgetTester t, double width, int selected) async {
    t.view.physicalSize = Size(width, 600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LinkModeBar<int>(
              label: 'ผูกกับ',
              tabs: tabs,
              selected: selected,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  bool cut(WidgetTester t, String label) =>
      t.renderObject<RenderParagraph>(find.text(label)).didExceedMaxLines;

  for (final width in [320.0, 390.0]) {
    testWidgets('$width wide: one row, equal tabs, no overflow; an icon '
        'never cuts its word', (t) async {
      for (var i = 0; i < tabs.length; i++) {
        await pumpBar(t, width, i);
        expect(t.takeException(), isNull);
        final label = t.getCenter(find.text('ผูกกับ'));
        final bar = t.getRect(find.byType(AppTabBar<int>));
        expect(label.dy, closeTo(bar.center.dy, 0.5)); // one row
        // Only the selected tab may show an icon (4 tabs) …
        final selectedIcon = find.byIcon(tabs[i].icon!);
        for (final other in tabs) {
          if (other.value != i) {
            expect(find.byIcon(other.icon!), findsNothing);
          }
        }
        // … and only if the word still fits beside it.
        if (selectedIcon.evaluate().isNotEmpty) {
          expect(cut(t, tabs[i].label), isFalse, reason: tabs[i].label);
        }
      }
    });
  }

  testWidgets('wide enough: the selected tab shows its icon', (t) async {
    await pumpBar(t, 900, 2);
    expect(find.byIcon(AppIcons.contact), findsOneWidget);
    expect(cut(t, 'จ่ายแทน'), isFalse);
  });

  testWidgets('ShareCard at 320: rows line up, status shows, no overflow', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ShareCard(
              title: 'ใครจ่าย และจ่ายเท่าไหร่ (a long header that wraps)',
              actions: [AppChip(label: 'หารเท่ากัน', onTap: () {})],
              rows: [
                ShareRow(
                  key: const ValueKey('me'),
                  avatar: const SizedBox.square(dimension: SplitRow.avatarSize),
                  name: const SplitRowName.muted('ฉันจ่ายเอง'),
                  amount: ShareAmountField(
                    key: const ValueKey('meAmount'),
                    value: 23,
                    auto: true,
                    onChanged: (_) {},
                  ),
                  trailing: AutoToggleChip(value: true, onChanged: (_) {}),
                ),
                ShareRow(
                  key: const ValueKey('payer'),
                  avatar: const SizedBox.square(dimension: SplitRow.avatarSize),
                  name: const SplitRowName.picked(
                    'A very long payer name that will not fit at all',
                  ),
                  amount: ShareAmountField(
                    key: const ValueKey('payerAmount'),
                    value: 100,
                    onChanged: (_) {},
                  ),
                  trailing: SplitRowAction(
                    icon: AppIcons.close,
                    tooltip: 'Remove',
                    onTap: () {},
                  ),
                  tag: const AppChip(
                    label: 'ใหม่ · เพิ่มเข้าอีเวนต์',
                    size: ChipSize.mini,
                  ),
                ),
              ],
              status: const ShareStatus('✓ จ่ายครบแล้ว', ok: true),
            ),
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
    final me = t.getRect(find.byKey(const ValueKey('meAmount')));
    final payer = t.getRect(find.byKey(const ValueKey('payerAmount')));
    expect(me.right, payer.right); // amounts in one column
    expect(me.width, ShareAmountField.width);
    final card = t.getRect(find.byType(ShareCard));
    expect(payer.right, lessThan(card.right));
    expect(find.byKey(const ValueKey('shareStatus')), findsOneWidget);
    expect(find.text('ใหม่ · เพิ่มเข้าอีเวนต์'), findsOneWidget);
  });

  testWidgets('AutoToggleChip flips; typing in an auto amount reports it', (
    t,
  ) async {
    var auto = true;
    double? typed;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SplitRow(
              avatar: const SizedBox.square(dimension: SplitRow.avatarSize),
              name: const SplitRowName.muted('ฉัน'),
              amount: ShareAmountField(
                value: 50,
                auto: auto,
                onChanged: (v) => setState(() {
                  typed = v;
                  auto = false;
                }),
              ),
              trailing: AutoToggleChip(
                value: auto,
                onChanged: (v) => setState(() => auto = v),
              ),
            ),
          ),
        ),
      ),
    );
    await t.enterText(find.byType(TextField), '70');
    await t.pump();
    expect(typed, 70);
    expect(auto, isFalse);
    await t.tap(find.byType(AutoToggleChip));
    await t.pump();
    expect(auto, isTrue);
  });
}
