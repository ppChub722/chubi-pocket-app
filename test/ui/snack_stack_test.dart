import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// SnackStack (A1, owner 2026-10-30): bottom only, the first snack at the
/// bottom, newer ones push the older ones up, above a bottom bar, from the
/// very bottom without one.
Future<void> _pump(
  WidgetTester t, {
  required Widget Function(BuildContext) page,
  Widget? bottomBar,
}) async {
  t.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1;
  await t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      home: Scaffold(
        bottomNavigationBar: bottomBar,
        body: Builder(builder: page),
      ),
    ),
  );
}

Rect _of(WidgetTester t, String text) => t.getRect(find.text(text));

void main() {
  testWidgets('the first snack at the bottom, newer ones above it', (t) async {
    addTearDown(t.view.reset);
    late BuildContext ctx;
    await _pump(
      t,
      page: (c) {
        ctx = c;
        return const SizedBox.expand();
      },
    );
    showAppSnackBar(ctx, 'first');
    await t.pump(const Duration(milliseconds: 400));
    showAppSnackBar(ctx, 'second');
    await t.pump(const Duration(milliseconds: 400));
    showAppSnackBar(ctx, 'third');
    await t.pump(const Duration(milliseconds: 400));
    expect(_of(t, 'first').top, greaterThan(_of(t, 'second').top));
    expect(_of(t, 'second').top, greaterThan(_of(t, 'third').top));
    // From the very bottom: the oldest sits just above the screen edge.
    expect(_of(t, 'first').bottom, lessThan(800));
    expect(_of(t, 'first').bottom, greaterThan(740));
    await t.pump(const Duration(seconds: 7));
    await t.pump(const Duration(milliseconds: 400));
  });

  testWidgets('a fourth pushes the oldest out; the same message replaces', (
    t,
  ) async {
    addTearDown(t.view.reset);
    late BuildContext ctx;
    await _pump(
      t,
      page: (c) {
        ctx = c;
        return const SizedBox.expand();
      },
    );
    for (final m in ['a', 'b', 'c', 'd']) {
      showAppSnackBar(ctx, m);
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('a'), findsNothing);
    expect(find.text('d'), findsOne);
    showAppSnackBar(ctx, 'b');
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('b'), findsOne);
    // 'b' came again: it is the newest, so it is above 'd'.
    expect(_of(t, 'b').top, lessThan(_of(t, 'd').top));
    await t.pump(const Duration(seconds: 7));
    await t.pump(const Duration(milliseconds: 400));
  });

  testWidgets('with a bottom bar the stack sits above it', (t) async {
    addTearDown(t.view.reset);
    late BuildContext ctx;
    await _pump(
      t,
      page: (c) {
        ctx = c;
        return const SizedBox.expand();
      },
      bottomBar: const SizedBox(height: 80, child: Text('bar')),
    );
    showAppSnackBar(ctx, 'hi');
    await t.pump(const Duration(milliseconds: 400));
    expect(_of(t, 'hi').bottom, lessThanOrEqualTo(_of(t, 'bar').top));
    await t.pump(const Duration(seconds: 7));
    await t.pump(const Duration(milliseconds: 400));
  });

  testWidgets('an action dismisses its snack and runs', (t) async {
    addTearDown(t.view.reset);
    late BuildContext ctx;
    await _pump(
      t,
      page: (c) {
        ctx = c;
        return const SizedBox.expand();
      },
    );
    var undone = 0;
    showAppSnackBar(
      ctx,
      'Deleted',
      actionLabel: 'Undo',
      onAction: () => undone++,
    );
    // the first frame starts the bar sliding in, the second finishes it
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Undo'));
    await t.pump(const Duration(milliseconds: 400));
    expect(undone, 1);
    expect(find.text('Deleted'), findsNothing);
  });

  testWidgets('a sticky snack stays under the pile and survives transients', (
    t,
  ) async {
    addTearDown(t.view.reset);
    late BuildContext ctx;
    await _pump(
      t,
      page: (c) {
        ctx = c;
        return const SizedBox.expand();
      },
    );
    final stack = SnackStack.of(ScaffoldMessenger.of(ctx));
    stack.setSticky('connection', (_) => const Text('offline'));
    await t.pump(const Duration(milliseconds: 400));
    showAppSnackBar(ctx, 'saved');
    await t.pump(const Duration(milliseconds: 400));
    // The sticky one came first: bottom; the transient one is above it.
    expect(_of(t, 'offline').top, greaterThan(_of(t, 'saved').top));
    await t.pump(const Duration(seconds: 7));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('saved'), findsNothing);
    expect(find.text('offline'), findsOne);
    // Hidden from outside (a page asked): the transient go, the sticky comes
    // back.
    stack.clearSticky('connection');
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('offline'), findsNothing);
  });
}
