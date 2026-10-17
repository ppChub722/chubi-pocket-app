import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Refresh on show (owner 2026-10-17): a page re-runs its ONE page call,
/// silently, when it becomes visible again — its tab switched back to, or a
/// PAGE popped from on top of it (not a sheet / dialog).
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  var calls = 0;
  Future<void> onRefresh() async => calls++;

  Widget list() => PullToRefresh(
    onRefresh: onRefresh,
    child: ListView(children: const [Text('row')]),
  );

  setUp(() => calls = 0);

  testWidgets('first show does not refresh; tab back to front does', (t) async {
    Widget host(bool active) => MaterialApp(
      theme: ThemeData(extensions: [colors]),
      home: TickerMode(
        enabled: active,
        child: Scaffold(body: list()),
      ),
    );
    await t.pumpWidget(host(true));
    await t.pump();
    expect(calls, 0);
    await t.pumpWidget(host(false));
    await t.pump();
    expect(calls, 0);
    await t.pumpWidget(host(true));
    await t.pump();
    expect(calls, 1);
  });

  testWidgets('a page popped from on top refreshes; a sheet does not', (
    t,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [PagePopObserver()],
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(body: list()),
      ),
    );
    await t.pump();
    expect(calls, 0);

    // A sheet over the page, then closed: no refresh.
    showModalBottomSheet<void>(
      context: nav.currentContext!,
      builder: (_) => const SizedBox(height: 100, child: Text('sheet')),
    );
    await t.pumpAndSettle();
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(calls, 0);

    // A page over the page, then popped: refresh once.
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('detail')),
      ),
    );
    await t.pumpAndSettle();
    expect(calls, 0);
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('disabled (editing) never refreshes on show', (t) async {
    Widget host(bool active) => MaterialApp(
      theme: ThemeData(extensions: [colors]),
      home: TickerMode(
        enabled: active,
        child: Scaffold(
          body: PullToRefresh(
            onRefresh: onRefresh,
            enabled: false,
            child: ListView(children: const [Text('row')]),
          ),
        ),
      ),
    );
    await t.pumpWidget(host(false));
    await t.pumpWidget(host(true));
    await t.pump();
    expect(calls, 0);
  });
}
