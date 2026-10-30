import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// BrandScreen (A3, owner 2026-10-30): the logo is one size at one y — the
/// system safe top + BrandScreen.logoTop — whatever is under it, the keyboard
/// or a top bar behind the body.
Future<Rect> _logoRect(
  WidgetTester t,
  Widget Function() screen, {
  double keyboard = 0,
  bool topBar = false,
}) async {
  t.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: 40)
    ..viewPadding = const FakeViewPadding(top: 40)
    ..viewInsets = FakeViewPadding(bottom: keyboard);
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: topBar ? AppBar(title: const Text('bar')) : null,
        extendBodyBehindAppBar: topBar,
        body: screen(),
      ),
    ),
  );
  return t.getRect(find.byType(BrandLogo));
}

Widget _short() => const BrandScreen(
  header: BrandHeader(name: 'chubiPocket'),
  children: [Text('hello')],
);

Widget _long() => BrandScreen(
  header: const BrandHeader(name: 'chubiPocket', tagline: 'Tagline'),
  children: [for (var i = 0; i < 30; i++) Text('field $i')],
);

void main() {
  testWidgets('one size, one y: short, long, keyboard, top bar', (t) async {
    addTearDown(t.view.reset);
    final cases = [
      await _logoRect(t, _short),
      await _logoRect(t, _long),
      await _logoRect(t, _long, keyboard: 300),
      await _logoRect(t, _short, topBar: true),
    ];
    for (final r in cases) {
      expect(r.top, 40 + BrandScreen.logoTop);
      expect(
        r.size,
        const Size(BrandLogo.standardSize, BrandLogo.standardSize),
      );
    }
  });

  testWidgets('a long form scrolls under the logo', (t) async {
    addTearDown(t.view.reset);
    await _logoRect(t, _long);
    await t.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await t.pump();
    expect(find.text('field 29'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
