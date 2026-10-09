import 'package:chubi_pocket/app/shell/main_shell.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A tab root: its name + a way to push a detail page, and optionally a
/// horizontal scroller (something that wants sideways drags itself).
Widget _root(String name, {bool withRow = false}) => Builder(
  builder: (context) => Scaffold(
    body: Column(
      children: [
        const SizedBox(height: 80),
        Text('tab $name'),
        TextButton(
          onPressed: () => context.push('/$name/detail'),
          child: const Text('open'),
        ),
        if (withRow)
          SizedBox(
            key: const Key('row'),
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 20; i++)
                  SizedBox(width: 80, child: Text('chip $i')),
              ],
            ),
          ),
        const Expanded(child: SizedBox.expand(key: Key('body'))),
      ],
    ),
  ),
);

GoRouter _router() => GoRouter(
  initialLocation: '/a',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        for (final (i, n) in ['a', 'b', 'c', 'd'].indexed)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/$n',
                builder: (_, _) => _root(n, withRow: i == 0),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (_, _) =>
                        Scaffold(body: Center(child: Text('detail $n'))),
                  ),
                ],
              ),
            ],
          ),
      ],
    ),
  ],
);

void main() {
  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: _router(),
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> swipe(WidgetTester t, Finder on, double dx) async {
    await t.fling(on, Offset(dx, 0), 1200);
    await t.pumpAndSettle();
  }

  testWidgets('swipe on a tab root → neighbouring tab, both ways', (t) async {
    await pump(t);
    expect(find.text('tab a'), findsOneWidget);
    await swipe(t, find.byKey(const Key('body')).first, -300);
    expect(find.text('tab b').hitTestable(), findsOneWidget);
    await swipe(t, find.text('tab b').hitTestable(), 300);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
    // First tab — swiping further right goes nowhere.
    await swipe(t, find.text('tab a').hitTestable(), 300);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
  });

  testWidgets('a horizontal scroller keeps its own swipe', (t) async {
    await pump(t);
    await swipe(t, find.byKey(const Key('row')), -300);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
  });

  testWidgets('a pushed page in the tab → no tab switch', (t) async {
    await pump(t);
    await t.tap(find.text('open').hitTestable());
    await t.pumpAndSettle();
    expect(find.text('detail a'), findsOneWidget);
    await swipe(t, find.text('detail a'), -300);
    expect(find.text('detail a').hitTestable(), findsOneWidget);
  });

  // ── System back ────────────────────────────────────────────────────

  Future<void> back(WidgetTester t) async {
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
  }

  testWidgets('back on another tab root → the dashboard (first tab)', (
    t,
  ) async {
    await pump(t);
    await swipe(t, find.byKey(const Key('body')).first, -300);
    await swipe(t, find.text('tab b').hitTestable(), -300);
    expect(find.text('tab c').hitTestable(), findsOneWidget);
    await back(t);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
  });

  testWidgets('back on a pushed page just pops it', (t) async {
    await pump(t);
    await t.tap(find.text('open').hitTestable());
    await t.pumpAndSettle();
    await back(t);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
    expect(find.text('detail a'), findsNothing);
  });

  testWidgets('back on the dashboard asks before closing the app', (t) async {
    await pump(t);
    await back(t);
    expect(find.text('ปิดแอป?'), findsOneWidget);
    await t.tap(find.text('ยกเลิก'));
    await t.pumpAndSettle();
    expect(find.text('ปิดแอป?'), findsNothing);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
  });
}
