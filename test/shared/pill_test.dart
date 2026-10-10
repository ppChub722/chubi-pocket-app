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

  // Two sizes app-wide (owner 2026-10-11): every chip 32, mini 20 only
  // for the tags on a transaction list row.
  testWidgets('every normal chip is 32 high', (t) async {
    await pump(
      t,
      Wrap(
        children: [
          const StatusPill(key: Key('s'), label: 'ค้าง'),
          const LabelPill(key: Key('l'), label: 'ผ่อน'),
          ActionPill(key: const Key('a'), label: 'ลบ', onTap: () {}),
          ChoicePill(
            key: const Key('c'),
            label: 'เดือน',
            selected: true,
            onTap: () {},
          ),
          RowChip(key: const Key('r'), label: 'อาหาร', onTap: () {}),
          FilterDropdownChip(key: const Key('f'), label: 'สี', onTap: () {}),
          SortChip<int>(
            key: const Key('o'),
            options: const [SortOption(0, 'ชื่อ')],
            selected: 0,
            onSelected: (_) {},
          ),
          const AppChip(key: Key('p'), label: 'ชิป'),
          const TagPill(
            key: Key('t'),
            name: 'เที่ยว',
            color: Colors.teal,
            size: PillSize.normal,
          ),
        ],
      ),
    );
    for (final k in ['s', 'l', 'a', 'c', 'r', 'f', 'o', 'p', 't']) {
      expect(t.getSize(find.byKey(Key(k))).height, 32, reason: k);
    }
  });

  testWidgets('mini is 20 (tags on a transaction row)', (t) async {
    await pump(
      t,
      const Wrap(
        children: [
          TagPill(key: Key('t'), name: 'เที่ยว', color: Colors.teal),
          LabelPill(key: Key('l'), label: '+2', size: PillSize.mini),
          AppChip(key: Key('p'), label: 'ชิป', size: PillSize.mini),
        ],
      ),
    );
    for (final k in ['t', 'l', 'p']) {
      expect(t.getSize(find.byKey(Key(k))).height, 20, reason: k);
    }
  });

  testWidgets('same label, same width — chips differ only by the label', (
    t,
  ) async {
    await pump(
      t,
      Wrap(
        children: [
          const LabelPill(key: Key('l'), label: 'ผ่อน'),
          RowChip(key: const Key('r'), label: 'ผ่อน', onTap: () {}),
          ChoicePill(
            key: const Key('c'),
            label: 'ผ่อน',
            selected: false,
            onTap: () {},
          ),
          const AppChip(key: Key('p'), label: 'ผ่อน'),
        ],
      ),
    );
    final w = t.getSize(find.byKey(const Key('l'))).width;
    for (final k in ['r', 'c', 'p']) {
      expect(
        t.getSize(find.byKey(Key(k))).width,
        moreOrLessEquals(w),
        reason: k,
      );
    }
  });

  testWidgets('StatusPill: a dot, ⌄ when tappable', (t) async {
    await pump(t, StatusPill(label: 'ค้าง', onTap: () {}));
    expect(t.getSize(find.byType(StatusPill)).height, PillSize.normal.height);
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
