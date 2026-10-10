import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      home: Scaffold(
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    ),
  );

  testWidgets('every role shares the size scale', (t) async {
    for (final s in PillSize.values) {
      await pump(
        t,
        Wrap(
          children: [
            StatusPill(key: const Key('s'), label: 'ค้าง', size: s),
            LabelPill(key: const Key('l'), label: 'ผ่อน', size: s),
            ActionPill(key: const Key('a'), label: 'ลบ', onTap: () {}, size: s),
            TagPill(
              key: const Key('t'),
              name: 'เที่ยว',
              color: Colors.teal,
              size: s,
            ),
          ],
        ),
      );
      for (final k in ['s', 'l', 'a', 't']) {
        expect(
          t.getSize(find.byKey(Key(k))).height,
          s.height,
          reason: '$k at ${s.name}',
        );
      }
    }
  });

  testWidgets('StatusPill: dense = small, a dot, ⌄ when tappable', (t) async {
    await pump(t, StatusPill(label: 'ค้าง', dense: true, onTap: () {}));
    expect(t.getSize(find.byType(StatusPill)).height, PillSize.small.height);
    expect(find.byType(Icon), findsOneWidget); // the ⌄
  });

  testWidgets('TagPill reads #name', (t) async {
    await pump(t, const TagPill(name: 'เที่ยว', color: Colors.teal));
    expect(find.text('#เที่ยว'), findsOneWidget);
  });

  testWidgets('PillOverflowRow: the first n, then +rest', (t) async {
    await pump(
      t,
      Row(
        children: [
          Flexible(
            child: PillOverflowRow(
              pills: [
                for (final n in ['a', 'b', 'c', 'd', 'e'])
                  TagPill(name: n, color: Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
    expect(find.text('#a'), findsOneWidget);
    expect(find.text('#b'), findsOneWidget);
    expect(find.text('#c'), findsNothing);
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('PillOverflowRow: no +n when everything fits the count', (
    t,
  ) async {
    await pump(
      t,
      Row(
        children: [
          Flexible(
            child: PillOverflowRow(
              maxVisible: 3,
              pills: [
                for (final n in ['a', 'b'])
                  TagPill(name: n, color: Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('a long label ellipsises instead of overflowing', (t) async {
    await pump(
      t,
      const Row(
        children: [
          Flexible(
            child: LabelPill(
              label: 'ชื่อยาวมากจนต้องตัดด้วยจุดสามจุดตรงท้ายจริง ๆ',
            ),
          ),
        ],
      ),
    );
    expect(t.takeException(), isNull);
  });
}
