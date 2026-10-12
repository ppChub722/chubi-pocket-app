import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('heading-less groups merge into ONE box at the top', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DetailPageBody(
            tags: const Text('tags'),
            sections: [
              (first) => SectionCard(
                first: first,
                title: 'Headed',
                children: const [Text('h1')],
              ),
              (first) => SectionCard(first: first, children: const [Text('a')]),
              (first) => SectionCard(first: first, children: const [Text('b')]),
            ],
          ),
        ),
      ),
    );
    final a = t.getRect(find.text('a'));
    final b = t.getRect(find.text('b'));
    final h = t.getRect(find.text('Headed'));
    expect(t.getRect(find.text('tags')).bottom, lessThanOrEqualTo(a.top));
    // a and b sit in the same box: 2 px apart, no section gap between.
    expect(b.top - a.bottom, lessThan(40));
    expect(a.top, lessThan(h.top));
    expect(b.top, lessThan(h.top));
    // One rounded group for the merged box + one for the headed section.
    expect(find.byType(DetailGroupScope), findsNWidgets(2));
  });

  testWidgets(
    'HeroDescription: empty hidden in view, 2 lines max, placeholder in edit',
    (t) async {
      final c = TextEditingController();
      Widget host(bool editing) => MaterialApp(
        home: Scaffold(
          body: HeroDescription(
            controller: c,
            editing: editing,
            hint: 'Description',
          ),
        ),
      );
      await t.pumpWidget(host(false));
      expect(find.byType(Text), findsNothing);
      c.text = List.filled(40, 'word').join(' ');
      await t.pump();
      final text = t.widget<Text>(find.byType(Text));
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      c.clear();
      await t.pumpWidget(host(true));
      expect(find.text('Description'), findsWidgets); // label + placeholder
    },
  );
}
