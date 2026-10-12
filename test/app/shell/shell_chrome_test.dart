import 'package:chubi_pocket/app/shell/shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records when [whenRouteSettled] fires for the page it's on.
class _Page extends StatefulWidget {
  const _Page({required this.onSettled});
  final VoidCallback onSettled;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  bool _asked = false;

  @override
  Widget build(BuildContext context) {
    if (!_asked) {
      _asked = true;
      whenRouteSettled(ModalRoute.of(context), widget.onSettled);
    }
    return const Scaffold(body: Text('page'));
  }
}

void main() {
  chromeRaceTests();
  testWidgets('fires once the page has slid in, not during', (t) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const Text('home')),
    );
    var fired = 0;
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => _Page(onSettled: () => fired++)),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(fired, 0, reason: 'still transitioning');
    await t.pumpAndSettle();
    expect(fired, 1);
  });

  testWidgets('popped before it settles → never fires', (t) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const Text('home')),
    );
    var fired = 0;
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => _Page(onSettled: () => fired++)),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(fired, 0);
  });

  testWidgets('already settled (or no route) → fires right away', (t) async {
    var fired = 0;
    whenRouteSettled(null, () => fired++);
    expect(fired, 1);
  });
}

/// The shell nav must NEVER stay hidden on a tab root — whatever the order of
/// pushes and pops (owner 2026-10-12: back pressed quickly from an edit page
/// left the bottom bar hidden).
void chromeRaceTests() {
  test('counted by owner: hidden while ANY owner holds it', () {
    final c = ShellChromeController();
    final a = Object();
    final b = Object();
    c.hide(owner: a);
    c.hide(owner: b);
    expect(c.hidden, isTrue);
    c.show(owner: a);
    expect(c.hidden, isTrue, reason: 'b still holds it');
    c.show(owner: b);
    expect(c.hidden, isFalse);
    c.show(owner: b); // releasing twice is harmless
    expect(c.hidden, isFalse);
  });

  Future<GlobalKey<NavigatorState>> pumpShell(
    WidgetTester t,
    ShellChromeController c,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      ShellChrome(
        controller: c,
        child: MaterialApp(navigatorKey: nav, home: const Text('tab root')),
      ),
    );
    return nav;
  }

  Route<void> editRoute() => MaterialPageRoute<void>(
    builder: (_) => const ShellChromeHider(child: Scaffold(body: Text('edit'))),
  );

  testWidgets('push then pop at once → shown', (t) async {
    final c = ShellChromeController();
    final nav = await pumpShell(t, c);
    nav.currentState!.push(editRoute());
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(c.hidden, isFalse);
  });

  testWidgets('pop during the push animation → shown', (t) async {
    final c = ShellChromeController();
    final nav = await pumpShell(t, c);
    nav.currentState!.push(editRoute());
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(c.hidden, isFalse);
  });

  testWidgets('settled, hidden, then pop → shown', (t) async {
    final c = ShellChromeController();
    final nav = await pumpShell(t, c);
    nav.currentState!.push(editRoute());
    await t.pumpAndSettle();
    expect(c.hidden, isTrue);
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(c.hidden, isFalse);
  });

  testWidgets('an edit page opening another, popped in any order → shown', (
    t,
  ) async {
    final c = ShellChromeController();
    final nav = await pumpShell(t, c);
    nav.currentState!.push(editRoute());
    await t.pumpAndSettle();
    nav.currentState!.push(editRoute());
    await t.pumpAndSettle();
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(c.hidden, isTrue, reason: 'the first edit page is still on');
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(c.hidden, isFalse);
  });

  testWidgets('double back during the animation → shown', (t) async {
    final c = ShellChromeController();
    final nav = await pumpShell(t, c);
    nav.currentState!.push(editRoute());
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    nav.currentState!.popUntil((r) => r.isFirst);
    nav.currentState!.popUntil((r) => r.isFirst);
    await t.pumpAndSettle();
    expect(c.hidden, isFalse);
  });
}
