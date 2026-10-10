import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final heroKey = GlobalKey();

  Future<void> pump(WidgetTester t, {bool disableAnimations = false}) =>
      t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Scaffold(
              body: CompactHeroScope(
                heroKey: heroKey,
                top: 0,
                bar: const CompactHeroBar(
                  leading: Icon(Icons.wallet),
                  title: Text('compact'),
                  trailing: Text('฿1'),
                ),
                child: ListView(
                  children: [
                    SizedBox(
                      key: heroKey,
                      height: 200,
                      child: const Text('hero'),
                    ),
                    for (var i = 0; i < 30; i++)
                      SizedBox(height: 60, child: Text('row $i')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  bool shown(WidgetTester t) =>
      t.widget<CompactHeroBar>(find.byType(CompactHeroBar)).visible;

  testWidgets('hidden at the top, shown once the hero scrolls away', (t) async {
    await pump(t);
    expect(shown(t), isFalse);

    // Part of the hero still below the line: stays hidden.
    await t.drag(find.byType(ListView), const Offset(0, -150));
    await t.pumpAndSettle();
    expect(shown(t), isFalse);

    // Hero fully past the line: shown.
    await t.drag(find.byType(ListView), const Offset(0, -100));
    await t.pumpAndSettle();
    expect(shown(t), isTrue);

    // Back to the top: hidden again.
    await t.drag(find.byType(ListView), const Offset(0, 600));
    await t.pumpAndSettle();
    expect(shown(t), isFalse);
  });

  testWidgets('a hero built away (scrolled far) counts as away', (t) async {
    await pump(t);
    await t.drag(find.byType(ListView), const Offset(0, -1500));
    await t.pumpAndSettle();
    expect(find.text('hero'), findsNothing);
    expect(shown(t), isTrue);
  });

  testWidgets('hidden bar ignores taps', (t) async {
    await pump(t);
    final ignore = t.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.text('compact'),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('animations off: no slide / fade duration', (t) async {
    await pump(t, disableAnimations: true);
    final slide = t.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    final fade = t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(slide.duration, Duration.zero);
    expect(fade.duration, Duration.zero);
  });
}
