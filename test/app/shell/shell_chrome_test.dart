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
