import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tab bar + pager, holding the selection like a page does.
class _Host extends StatefulWidget {
  const _Host({this.enabled = true, this.count = 2});
  final bool enabled;
  final int count;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int tab = 0;
  final pages = PageController();

  static const _icons = [
    AppIcons.pie,
    AppIcons.receipt,
    AppIcons.history,
    AppIcons.member,
  ];

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          AppTabBar<int>(
            key: const ValueKey('bar'),
            selected: tab,
            onChanged: (v) => setState(() => tab = v),
            pager: pages,
            tabs: [
              for (var i = 0; i < widget.count; i++)
                AppTab(value: i, label: 'T$i', icon: _icons[i]),
            ],
          ),
          Text('selected $tab'),
          Expanded(
            child: AppTabPager<int>(
              controller: pages,
              values: [for (var i = 0; i < widget.count; i++) i],
              selected: tab,
              onChanged: (v) => setState(() => tab = v),
              enabled: widget.enabled,
              builder: (context, v) => SizedBox.expand(child: Text('page $v')),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  Rect pill(WidgetTester t) => t.getRect(
    find.descendant(
      of: find.byKey(AppTabBar.pillKey),
      matching: find.byType(DecoratedBox),
    ),
  );

  testWidgets('a pill track: 40 high, equal segments, the pill on the '
      'selected segment', (t) async {
    await t.pumpWidget(const _Host(count: 3));
    final bar = t.getRect(find.byKey(const ValueKey('bar')));
    expect(bar.height, AppTabBar.height);
    // Inner width (1 px border + 3 px padding each side) / 3.
    final segment = (bar.width - 8) / 3;
    expect(pill(t).width, closeTo(segment, 0.01));
    expect(pill(t).left, closeTo(bar.left + 4, 0.01));
    final labels = [for (var i = 0; i < 3; i++) t.getCenter(find.text('T$i'))];
    // Each label sits in its own equal segment (icon + text, centred).
    for (var i = 0; i < 3; i++) {
      final cx = bar.left + 4 + segment * (i + 0.5);
      expect(labels[i].dx, closeTo(cx, segment / 2));
    }
    await t.tap(find.text('T2'));
    await t.pumpAndSettle();
    expect(pill(t).left, closeTo(bar.left + 4 + 2 * segment, 0.01));
  });

  testWidgets('icons: every tab with 2–3 tabs, only the selected with 4', (
    t,
  ) async {
    await t.pumpWidget(const _Host(count: 3));
    expect(find.byIcon(AppIcons.pie), findsOneWidget);
    expect(find.byIcon(AppIcons.receipt), findsOneWidget);
    expect(find.byIcon(AppIcons.history), findsOneWidget);
    await t.pumpWidget(const _Host(count: 4));
    expect(find.byIcon(AppIcons.pie), findsOneWidget);
    expect(find.byIcon(AppIcons.receipt), findsNothing);
    expect(find.byIcon(AppIcons.member), findsNothing);
  });

  testWidgets('a drag ON THE BAR changes the tab (the pill follows the '
      'finger, then snaps)', (t) async {
    await t.pumpWidget(const _Host());
    final bar = t.getRect(find.byKey(const ValueKey('bar')));
    final g = await t.startGesture(bar.centerLeft + const Offset(60, 0));
    await g.moveBy(const Offset(40, 0));
    await g.moveBy(const Offset(200, 0));
    await t.pump();
    final mid = pill(t).left;
    expect(mid, greaterThan(bar.left + 4)); // moving with the finger
    await g.up();
    await t.pumpAndSettle();
    expect(find.text('selected 1'), findsOneWidget);
    expect(find.text('page 1'), findsOneWidget);
    expect(pill(t).left, closeTo(bar.left + 4 + (bar.width - 8) / 2, 0.01));
  });

  testWidgets('a short drag on the bar snaps back', (t) async {
    await t.pumpWidget(const _Host());
    final bar = t.getRect(find.byKey(const ValueKey('bar')));
    await t.dragFrom(bar.centerLeft + const Offset(60, 0), const Offset(60, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 0'), findsOneWidget);
    expect(pill(t).left, closeTo(bar.left + 4, 0.01));
  });

  testWidgets('a swipe on the CONTENT changes the tab too; the pill rides it', (
    t,
  ) async {
    await t.pumpWidget(const _Host());
    final bar = t.getRect(find.byKey(const ValueKey('bar')));
    await t.drag(find.byType(PageView), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 1'), findsOneWidget);
    expect(pill(t).left, closeTo(bar.left + 4 + (bar.width - 8) / 2, 0.01));
    // Already on the last tab: another left swipe stays.
    await t.drag(find.byType(PageView), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 1'), findsOneWidget);
    await t.drag(find.byType(PageView), const Offset(500, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 0'), findsOneWidget);
  });

  testWidgets('content swipe disabled (edit / reorder): the bar still works', (
    t,
  ) async {
    await t.pumpWidget(const _Host(enabled: false));
    await t.drag(find.byType(PageView), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 0'), findsOneWidget);
    await t.tap(find.text('T1'));
    await t.pumpAndSettle();
    expect(find.text('selected 1'), findsOneWidget);
  });

  testWidgets('a tap slides the page and the pill together (300 ms)', (
    t,
  ) async {
    await t.pumpWidget(const _Host());
    final bar = t.getRect(find.byKey(const ValueKey('bar')));
    await t.tap(find.text('T1'));
    await t.pump(); // starts the slide
    await t.pump(const Duration(milliseconds: 120));
    final mid = pill(t).left;
    await t.pumpAndSettle();
    final end = pill(t).left;
    expect(end, closeTo(bar.left + 4 + (bar.width - 8) / 2, 0.01));
    expect(mid, inExclusiveRange(bar.left + 4, end)); // moving, not jumping
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('without a pager the pill animates to the tab by itself', (
    t,
  ) async {
    var sel = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppTabBar<int>(
              key: const ValueKey('bar'),
              selected: sel,
              onChanged: (v) => setState(() => sel = v),
              tabs: const [
                AppTab(value: 0, label: 'A'),
                AppTab(value: 1, label: 'B'),
              ],
            ),
          ),
        ),
      ),
    );
    final bar = t.getRect(find.byKey(const ValueKey('bar')));
    final g = await t.startGesture(bar.centerLeft + const Offset(60, 0));
    await g.moveBy(const Offset(40, 0));
    await g.moveBy(const Offset(260, 0));
    await g.up();
    await t.pumpAndSettle();
    expect(sel, 1);
    expect(pill(t).left, closeTo(bar.left + 4 + (bar.width - 8) / 2, 0.01));
  });
}
