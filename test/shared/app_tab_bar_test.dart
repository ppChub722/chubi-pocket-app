import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tab bar + pager, holding the selection like a page does.
class _Host extends StatefulWidget {
  const _Host({this.enabled = true});
  final bool enabled;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int tab = 0;
  final pages = PageController();

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
            selected: tab,
            onChanged: (v) => setState(() => tab = v),
            pager: pages,
            tabs: const [
              AppTab(value: 0, label: 'A'),
              AppTab(value: 1, label: 'B'),
            ],
          ),
          Text('selected $tab'),
          Expanded(
            child: AppTabPager<int>(
              controller: pages,
              values: const [0, 1],
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
  testWidgets('swipe left → next tab, swipe right → back', (t) async {
    await t.pumpWidget(const _Host());
    await t.drag(find.byType(PageView), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 1'), findsOneWidget);

    // Already on the last tab — another left swipe stays.
    await t.drag(find.byType(PageView), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 1'), findsOneWidget);

    await t.drag(find.byType(PageView), const Offset(500, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 0'), findsOneWidget);
  });

  testWidgets('disabled → a swipe does nothing', (t) async {
    await t.pumpWidget(const _Host(enabled: false));
    await t.drag(find.byType(PageView), const Offset(-500, 0));
    await t.pumpAndSettle();
    expect(find.text('selected 0'), findsOneWidget);
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('tapping a tab slides the page and the underline with it', (
    t,
  ) async {
    await t.pumpWidget(const _Host());
    double underlineLeft() =>
        t.getTopLeft(find.byKey(AppTabBar.underlineKey)).dx;
    expect(underlineLeft(), 0);
    await t.tap(find.text('B'));
    await t.pump(); // starts the slide
    await t.pump(const Duration(milliseconds: 160));
    final mid = underlineLeft();
    await t.pumpAndSettle();
    final end = underlineLeft();
    expect(end, closeTo(400, 0.5)); // half of the 800-wide test screen
    expect(mid, inExclusiveRange(0, end)); // moving, not jumping
    expect(find.text('page 1'), findsOneWidget);
  });
}
