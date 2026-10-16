import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);
  Widget host(Widget child) => MaterialApp(
    theme: ThemeData(extensions: [colors]),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('tile taps fire; selected tile gets the primary ring', (t) async {
    final taps = <String>[];
    await t.pumpWidget(
      host(
        ListSummaryCard(
          caption: 'Cap',
          amount: 100,
          symbol: '฿',
          tiles: [
            SummaryTile(label: 'A', value: '1', onTap: () => taps.add('A')),
            SummaryTile(
              label: 'B',
              value: '2',
              selected: true,
              tone: SummaryTileTone.red,
              onTap: () => taps.add('B'),
            ),
          ],
        ),
      ),
    );
    await t.tap(find.byKey(const ValueKey('summaryTile:A')));
    await t.tap(find.byKey(const ValueKey('summaryTile:B')));
    expect(taps, ['A', 'B']);
    final frames = t
        .widgetList<SelectableFrame>(find.byType(SelectableFrame))
        .map((f) => f.selected)
        .toList();
    expect(frames, [false, true]);
    expect(find.text('Cap'), findsOneWidget);
  });

  testWidgets('alert, info, cta and the action slot', (t) async {
    var alert = 0, cta = 0, act = 0;
    await t.pumpWidget(
      host(
        ListSummaryCard(
          actions: [CardActionButton(icon: Icons.search, onTap: () => act++)],
          amount: 5,
          mainSuffix: 'of 9',
          alert: 'Heads up',
          onAlertTap: () => alert++,
          infoLine: const Text('Info'),
          cta: SummaryCta(label: 'Go', onTap: () => cta++),
        ),
      ),
    );
    expect(find.text('of 9'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('summaryAlert')));
    await t.tap(find.text('Go'));
    await t.tap(find.byType(CardActionButton));
    expect([alert, cta, act], [1, 1, 1]);
  });

  testWidgets('no alert / cta / tiles when not given', (t) async {
    await t.pumpWidget(host(const ListSummaryCard(amount: 1)));
    expect(find.byKey(const ValueKey('summaryAlert')), findsNothing);
    expect(find.byType(AppButton), findsNothing);
    expect(find.byType(SelectableFrame), findsNothing);
  });
}
