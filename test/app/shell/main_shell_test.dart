import 'package:chubi_pocket/app/shell/fade_branch_container.dart';
import 'package:chubi_pocket/app/shell/main_shell.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A tab root: its name + a way to open its own detail page and another
/// tab's, and optionally a horizontal scroller (something that wants
/// sideways drags itself).
Widget _root(String name, {bool withRow = false}) => Builder(
  builder: (context) => Scaffold(
    body: TabSwitchBody(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Text('tab $name'),
          TextButton(
            onPressed: () => openPage(context, '/$name/detail'),
            child: const Text('open'),
          ),
          TextButton(
            onPressed: () => openPage(context, '/projects/detail'),
            child: const Text('open project'),
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
  ),
);

/// Swipes right that tab c's page spent on itself (like the dashboard's
/// month).
int _pageSwipes = 0;

/// Registers tab c's root as a [ShellSwipeHandler] taking swipes right.
class _SwipeOwner extends StatefulWidget {
  const _SwipeOwner({required this.child});
  final Widget child;

  @override
  State<_SwipeOwner> createState() => _SwipeOwnerState();
}

class _SwipeOwnerState extends State<_SwipeOwner> implements ShellSwipeHandler {
  @override
  bool canSwipe(int dir) => dir < 0;

  @override
  void onSwipe(int dir) => _pageSwipes++;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ShellSwipeScope.maybeOf(context)?[ShellTab.accounts] = this;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One branch per [ShellTab], like the app: the four nav tabs are a–d (d =
/// the เพิ่มเติม hub), the rest go by their tab name. Details are siblings
/// of their root, as in app_router.dart.
GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute(
      navigatorContainerBuilder: (context, navigationShell, children) =>
          FadeBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        for (final tab in ShellTab.values)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/${_name(tab)}',
                builder: (_, _) => tab == ShellTab.accounts
                    ? _SwipeOwner(child: _root(_name(tab)))
                    : _root(_name(tab), withRow: tab == ShellTab.home),
              ),
              GoRoute(
                path: '/${_name(tab)}/detail',
                builder: (_, _) =>
                    Scaffold(body: Center(child: Text('detail ${_name(tab)}'))),
              ),
            ],
          ),
      ],
    ),
  ],
);

String _name(ShellTab tab) => tab.inNav ? 'abcd'[tab.index] : tab.name;

void main() {
  Future<void> pump(
    WidgetTester t, {
    String at = '/a',
    bool reduceMotion = false,
  }) async {
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: _router(at),
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
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
    await swipe(t, find.text('tab a').hitTestable(), -300);
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

  // ── Motion ─────────────────────────────────────────────────────────

  double x(WidgetTester t, String tab) =>
      t.getTopLeft(find.text('tab $tab').hitTestable()).dx;

  testWidgets('mid-drag the body trails the finger a little, then settles', (
    t,
  ) async {
    await pump(t);
    final rest = x(t, 'a');
    final g = await t.startGesture(t.getCenter(find.byKey(const Key('body'))));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(-20, 0));
      await t.pump(const Duration(milliseconds: 100));
    }
    final shift = x(t, 'a') - rest;
    expect(shift, lessThan(0)); // follows the finger leftwards…
    expect(shift, greaterThan(-24)); // …but only a little
    // Released slowly → no switch, back in place.
    await g.up();
    await t.pumpAndSettle();
    expect(find.text('tab a').hitTestable(), findsOneWidget);
    expect(x(t, 'a'), rest);
  });

  testWidgets('the new tab slides in from the side it lies on', (t) async {
    await pump(t);
    final rest = x(t, 'a');
    Future<void> flingThenPeek(Finder on, double dx) async {
      await t.fling(on, Offset(dx, 0), 1200);
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
    }

    // Swipe left → tab b, entering from the right.
    await flingThenPeek(find.text('tab a').hitTestable(), -300);
    expect(x(t, 'b'), greaterThan(rest));
    await t.pumpAndSettle();
    expect(x(t, 'b'), rest);
    // Swipe right → back to tab a, entering from the left.
    await flingThenPeek(find.text('tab b').hitTestable(), 300);
    expect(x(t, 'a'), lessThan(rest));
    await t.pumpAndSettle();
    expect(x(t, 'a'), rest);
  });

  testWidgets('a swipe the page takes: no tab nudge, the page handles it', (
    t,
  ) async {
    await pump(t, at: '/c');
    _pageSwipes = 0;
    final rest = x(t, 'c');
    final g = await t.startGesture(t.getCenter(find.text('tab c')));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(20, 0));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(x(t, 'c'), rest); // the tab doesn't move as if switching
    await g.up();
    await t.pumpAndSettle();
    await swipe(t, find.text('tab c').hitTestable(), 300);
    expect(_pageSwipes, 1);
    expect(find.text('tab c').hitTestable(), findsOneWidget);
  });

  testWidgets('landing on a detail page fades the tab in, not a snap', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('open project').hitTestable());
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    bool fading(Layer? l) {
      for (var c = l; c != null; c = c.nextSibling) {
        if (c is OpacityLayer && (c.alpha ?? 255) < 255) return true;
        if (c is ContainerLayer && fading(c.firstChild)) return true;
      }
      return false;
    }

    expect(fading(t.layers.first), isTrue);
    await t.pumpAndSettle();
    expect(fading(t.layers.first), isFalse);
  });

  testWidgets('reduced motion: tabs fade, no slide, no nudge', (t) async {
    await pump(t, reduceMotion: true);
    final rest = x(t, 'a');
    final g = await t.startGesture(t.getCenter(find.text('tab a')));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(-20, 0));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(x(t, 'a'), rest);
    await g.up();
    await t.pumpAndSettle();
    await t.fling(
      find.text('tab a').hitTestable(),
      const Offset(-300, 0),
      1200,
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(x(t, 'b'), rest);
    await t.pumpAndSettle();
  });

  // ── System back ────────────────────────────────────────────────────

  Future<void> back(WidgetTester t) async {
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
  }

  testWidgets('back on a tab root walks the tabs visited, newest first', (
    t,
  ) async {
    await pump(t);
    await swipe(t, find.text('tab a').hitTestable(), -300);
    await swipe(t, find.text('tab b').hitTestable(), -300);
    expect(find.text('tab c').hitTestable(), findsOneWidget);
    await back(t);
    expect(find.text('tab b').hitTestable(), findsOneWidget);
    await back(t);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
    // Going back built no forward trail: next is the exit prompt.
    await back(t);
    expect(find.text('ปิดแอป?'), findsOneWidget);
  });

  testWidgets('no history: a nav tab → the dashboard', (t) async {
    await pump(t, at: '/c');
    await back(t);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
  });

  testWidgets('no history: a เพิ่มเติม card tab → the hub → the dashboard', (
    t,
  ) async {
    await pump(t, at: '/projects');
    await back(t);
    expect(find.text('tab d').hitTestable(), findsOneWidget);
    await back(t);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
  });

  testWidgets('swipe moves along its own row, never into the next', (t) async {
    // The nav ends at เพิ่มเติม.
    await pump(t, at: '/d');
    await swipe(t, find.text('tab d').hitTestable(), -300);
    expect(find.text('tab d').hitTestable(), findsOneWidget);
    // The top bar's row: ⏳ ↔ 🔔 ↔ 👤.
    await pump(t, at: '/notifications');
    await swipe(t, find.text('tab notifications').hitTestable(), -300);
    expect(find.text('tab settings').hitTestable(), findsOneWidget);
    await swipe(t, find.text('tab settings').hitTestable(), -300);
    expect(find.text('tab settings').hitTestable(), findsOneWidget);
    // A เพิ่มเติม section, in the hub's order: contacts ↔ projects ↔ debts.
    await pump(t, at: '/projects');
    await swipe(t, find.text('tab projects').hitTestable(), 300);
    expect(find.text('tab contacts').hitTestable(), findsOneWidget);
    // Library's last card doesn't spill into the people section.
    await pump(t, at: '/tags');
    await swipe(t, find.text('tab tags').hitTestable(), -300);
    expect(find.text('tab tags').hitTestable(), findsOneWidget);
  });
  testWidgets('another tab\'s page opens in its own tab; back returns', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('open project').hitTestable());
    await t.pumpAndSettle();
    expect(find.text('detail projects').hitTestable(), findsOneWidget);
    // Landed alone in the projects tab — nothing stacked onto tab a.
    await back(t);
    expect(find.text('tab a').hitTestable(), findsOneWidget);
    expect(find.text('detail projects').hitTestable(), findsNothing);
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
