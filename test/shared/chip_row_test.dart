import 'package:chubi_pocket/shared/widgets/chips/chip_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed-size chip, so line maths don't depend on the test font.
Widget _chip(int i) =>
    SizedBox(key: ValueKey('c$i'), width: 100, height: 30, child: Text('$i'));

Future<void> _pump(
  WidgetTester tester, {
  required int count,
  int? maxLines,
  bool more = true,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 250, // two 100-wide chips (+ 4 gap) a line
          child: ChipRow(
            maxLines: maxLines,
            onMore: more ? () {} : null,
            moreLabel: 'more',
            chips: [for (var i = 0; i < count; i++) _chip(i)],
          ),
        ),
      ),
    ),
  ),
);

/// Chips that paint (the cut ones are laid out but not painted).
bool _shown(WidgetTester tester, int i) =>
    find.byKey(ValueKey('c$i')).hitTestable().evaluate().isNotEmpty;

void main() {
  testWidgets('maxLines: everything fits — all chips, then เพิ่มเติม', (
    tester,
  ) async {
    await _pump(tester, count: 3, maxLines: 4);
    for (var i = 0; i < 3; i++) {
      expect(_shown(tester, i), isTrue);
    }
    expect(find.text('more').hitTestable(), findsOneWidget);
  });

  testWidgets('maxLines: past the limit — cut, เพิ่มเติม ends the last line', (
    tester,
  ) async {
    await _pump(tester, count: 10, maxLines: 2);
    // Line 1: 0, 1. Line 2: 2, then "more" — 3 makes way for it.
    expect(_shown(tester, 0), isTrue);
    expect(_shown(tester, 1), isTrue);
    expect(_shown(tester, 2), isTrue);
    for (var i = 3; i < 10; i++) {
      expect(_shown(tester, i), isFalse, reason: 'chip $i is cut');
    }
    final more = tester.getTopLeft(find.text('more'));
    final second = tester.getTopLeft(find.byKey(const ValueKey('c2')));
    expect(more.dy, greaterThanOrEqualTo(second.dy - 1));
    // Two lines high, not ten.
    expect(tester.getSize(find.byType(ChipRow)).height, lessThan(80));
  });

  testWidgets('no maxLines: one line that scrolls sideways', (tester) async {
    await _pump(tester, count: 10);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.getSize(find.byType(ChipRow)).height, lessThan(40));
  });
}
