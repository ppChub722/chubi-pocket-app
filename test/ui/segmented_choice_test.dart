import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Widget host({bool enabled = true, required ValueChanged<String> on}) =>
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: SegmentedChoice<String>(
            selected: 'b',
            enabled: enabled,
            onChanged: on,
            segments: const [
              ChoiceSegment('a', 'A'),
              ChoiceSegment('b', 'B'),
              ChoiceSegment('c', 'C'),
            ],
          ),
        ),
      );

  testWidgets('tapping another segment reports it; the chosen one is silent', (
    t,
  ) async {
    final got = <String>[];
    await t.pumpWidget(host(on: got.add));
    await t.tap(find.text('B'));
    await t.tap(find.text('C'));
    expect(got, ['c']);
  });

  testWidgets('disabled ignores taps', (t) async {
    final got = <String>[];
    await t.pumpWidget(host(enabled: false, on: got.add));
    await t.tap(find.text('A'));
    expect(got, isEmpty);
  });
}
