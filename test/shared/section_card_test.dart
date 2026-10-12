import 'package:chubi_pocket/ui/ui.dart';
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

  testWidgets('rows are 2 px apart (no hairlines); only first / last round', (
    t,
  ) async {
    await pump(
      t,
      const SectionCard(
        first: true,
        title: 'T',
        children: [Text('a'), Text('b'), Text('c')],
      ),
    );
    expect(find.byType(AppDivider), findsNothing);
    final a = t.getRect(
      find.ancestor(of: find.text('a'), matching: find.byType(ClipRRect)).first,
    );
    final b = t.getRect(
      find.ancestor(of: find.text('b'), matching: find.byType(ClipRRect)).first,
    );
    expect(b.top - a.bottom, 2);
    final clips = t.widgetList<ClipRRect>(find.byType(ClipRRect)).toList();
    final radii = [
      for (final c in clips) (c.borderRadius as BorderRadius).topLeft.x,
    ];
    expect(radii.first, greaterThan(0));
    expect(radii[1], 0);
    expect(
      (clips.last.borderRadius as BorderRadius).bottomLeft.x,
      greaterThan(0),
    );
  });

  testWidgets('dividers: false — the rows touch', (t) async {
    await pump(
      t,
      const SectionCard(
        first: true,
        title: 'T',
        dividers: false,
        children: [Text('a'), Text('b')],
      ),
    );
    final a = t.getRect(
      find.ancestor(of: find.text('a'), matching: find.byType(ClipRRect)).first,
    );
    final b = t.getRect(
      find.ancestor(of: find.text('b'), matching: find.byType(ClipRRect)).first,
    );
    expect(b.top, a.bottom);
  });

  testWidgets('heading and description sit ABOVE the container', (t) async {
    await pump(
      t,
      const SectionCard(
        first: true,
        title: 'หัวข้อ',
        description: 'คำอธิบาย',
        children: [Text('a')],
      ),
    );
    final box = t.getRect(
      find.ancestor(of: find.text('a'), matching: find.byType(ClipRRect)).first,
    );
    expect(t.getRect(find.text('หัวข้อ')).bottom, lessThanOrEqualTo(box.top));
    expect(t.getRect(find.text('คำอธิบาย')).bottom, lessThanOrEqualTo(box.top));
    expect(
      t.getRect(find.text('หัวข้อ')).bottom,
      lessThanOrEqualTo(t.getRect(find.text('คำอธิบาย')).top + 1),
    );
  });

  testWidgets('not first — a gap above; first — none', (t) async {
    await pump(t, const SectionCard(children: [Text('a')]));
    final notFirst = t.getRect(find.text('a')).top;
    await pump(t, const SectionCard(first: true, children: [Text('a')]));
    expect(notFirst - t.getRect(find.text('a')).top, 16);
  });

  testWidgets('one row with an icon: every row reserves the icon slot', (
    t,
  ) async {
    await pump(
      t,
      const SectionCard(
        first: true,
        children: [
          DetailRow(icon: Icons.wallet, label: 'with icon'),
          DetailRow(label: 'without icon'),
        ],
      ),
    );
    expect(
      t.getRect(find.text('without icon')).left,
      t.getRect(find.text('with icon')).left,
    );
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
