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

  const style = HeroStyle.plain();

  testWidgets('view: rows A–G in order, ✏️ is the standard slot', (t) async {
    var edited = false;
    await t.pumpWidget(
      host(
        HeroCard(
          style: style,
          chips: const [AppChip(label: 'chip')],
          onEdit: () => edited = true,
          icon: const SizedBox(width: 40, height: 40, key: Key('icon')),
          description: const Text('desc'),
          number: const HeroNumber(label: 'label', value: Text('1,000')),
          bar: const HeroBar(value: 0.5, left: 'left', right: 'right'),
          tiles: const [Text('t1'), Text('t2')],
          alert: const HeroAlert(text: 'alert'),
          embedded: const Text('embedded'),
          settingsLine: const Text('settings'),
        ),
      ),
    );
    double y(Finder f) => t.getTopLeft(f).dy;
    final order = [
      find.text('chip'),
      find.byKey(const Key('icon')),
      find.text('label'),
      find.text('left'),
      find.text('t1'),
      find.text('alert'),
      find.text('embedded'),
      find.text('settings'),
    ];
    for (var i = 1; i < order.length; i++) {
      expect(y(order[i]), greaterThan(y(order[i - 1])), reason: 'row $i');
    }
    final edit = find.byType(CardActionButton);
    expect(edit, findsOneWidget);
    expect(t.getSize(edit).width, ControlSizes.fallback.control);
    await t.tap(edit);
    expect(edited, isTrue);
    // The number is on its own row, under the icon row (never beside it).
    expect(
      y(find.text('1,000')),
      greaterThan(y(find.byKey(const Key('icon')))),
    );
  });

  testWidgets('edit variant hides the slot and rows D–G', (t) async {
    final c = TextEditingController(text: '5');
    await t.pumpWidget(
      host(
        HeroCard(
          style: style,
          editing: true,
          chips: const [AppChip(label: 'chip')],
          onEdit: () {},
          search: const Text('search'),
          icon: const SizedBox(width: 44, height: 44),
          description: const Text('desc'),
          number: const HeroNumber(label: 'label', value: Text('1,000')),
          amountField: HeroAmountField(controller: c, label: 'target'),
          bar: const HeroBar(value: 0.5),
          tiles: const [Text('t1')],
          alert: const HeroAlert(text: 'alert'),
          embedded: const Text('embedded'),
          settingsLine: const Text('settings'),
        ),
      ),
    );
    expect(find.byType(CardActionButton), findsNothing);
    expect(find.text('search'), findsNothing);
    expect(find.text('chip'), findsOneWidget);
    expect(find.byType(HeroNumber), findsNothing);
    expect(find.byType(HeroAmountField), findsOneWidget);
    for (final gone in ['t1', 'alert', 'embedded', 'settings']) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    expect(find.byType(ProgressRow), findsNothing);
  });

  testWidgets('a row with nothing in it collapses (no empty top row)', (
    t,
  ) async {
    await t.pumpWidget(
      host(HeroCard(style: style, description: const Text('only desc'))),
    );
    expect(find.byType(HeroTopRow), findsNothing);
    expect(find.text('only desc'), findsOneWidget);
  });

  testWidgets('DetailLayout puts the slots in the fixed order', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: const Scaffold(
          body: DetailLayout(
            hero: Text('hero'),
            records: Text('records'),
            note: Text('note'),
            settings: Text('settings'),
            info: Text('info'),
            tags: Text('tags'),
            metaLines: ['meta'],
          ),
        ),
      ),
    );
    final names = [
      'hero',
      'tags',
      'info',
      'settings',
      'note',
      'records',
      'meta',
    ];
    for (var i = 1; i < names.length; i++) {
      expect(
        t.getTopLeft(find.text(names[i])).dy,
        greaterThan(t.getTopLeft(find.text(names[i - 1])).dy),
        reason: names[i],
      );
    }
  });
}
