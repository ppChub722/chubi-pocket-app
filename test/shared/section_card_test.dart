import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [child],
        ),
      ),
    ),
  );

  testWidgets('a hairline between rows, none before or after', (t) async {
    await pump(
      t,
      const SectionCard(
        first: true,
        children: [Text('a'), Text('b'), Text('c')],
      ),
    );
    expect(find.byType(RowDivider), findsNWidgets(2));
    expect(find.byType(SectionBand), findsNothing);
  });

  testWidgets('dividers: false — no hairlines', (t) async {
    await pump(
      t,
      const SectionCard(
        first: true,
        dividers: false,
        children: [Text('a'), Text('b')],
      ),
    );
    expect(find.byType(RowDivider), findsNothing);
  });

  testWidgets('not first — a band above, reaching the screen edges', (t) async {
    await pump(t, const SectionCard(title: 'หัวข้อ', children: [Text('a')]));
    expect(find.byType(SectionBand), findsOneWidget);
    final band = t.getRect(
      find.descendant(
        of: find.byType(SectionBand),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(band.left, 0);
    expect(band.right, t.view.physicalSize.width / t.view.devicePixelRatio);
  });

  testWidgets('trailing sits on the title row', (t) async {
    await pump(
      t,
      const SectionCard(
        first: true,
        title: 'หัวข้อ',
        trailing: Icon(Icons.share),
        children: [Text('a')],
      ),
    );
    expect(
      t.getCenter(find.byIcon(Icons.share)).dy,
      closeTo(t.getCenter(find.text('หัวข้อ')).dy, 12),
    );
  });
}
