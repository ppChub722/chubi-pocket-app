import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Widget host({bool dots = true}) {
    final controller = PageController();
    return MaterialApp(
      theme: ThemeData(extensions: [colors]),
      home: Scaffold(
        body: TabbedListPageBody<int>(
          tabs: const [
            AppTab(value: 0, label: 'One'),
            AppTab(value: 1, label: 'Two'),
          ],
          selected: 0,
          onChanged: (_) {},
          controller: controller,
          showPageDots: dots,
          pageBuilder: (context, tab) => ListPageBody(
            loading: false,
            error: null,
            isEmpty: false,
            onRetry: () async {},
            empty: const EmptyView.compact(message: 'none'),
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(height: 60, child: Text('r$i')),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('PageDots: current is the wider pill', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: const Scaffold(body: PageDots(count: 3, index: 1)),
      ),
    );
    final cur = t.getSize(find.byKey(const ValueKey('pageDotCurrent')));
    final other = t.getSize(find.byKey(const ValueKey('pageDot0')));
    expect(cur.width, greaterThan(other.width));
  });

  testWidgets('indicator is in the flow: last child, scrolls with content', (
    t,
  ) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();
    final dots = find.byType(PageDots);
    // Not on screen at the top: it is the END of the list, not floating.
    expect(dots, findsNothing);
    await t.drag(find.byType(ListView), const Offset(0, -1500));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView), const Offset(0, -3000));
    await t.pumpAndSettle();
    expect(dots, findsOneWidget);
    final after = t.getTopLeft(dots).dy;
    // It sits below the last row.
    expect(after, greaterThan(t.getBottomLeft(find.text('r29')).dy - 1));
    // And lives inside the ListView.
    expect(
      find.descendant(of: find.byType(ListView), matching: dots),
      findsOneWidget,
    );
  });

  testWidgets('showPageDots: false renders none', (t) async {
    await t.pumpWidget(host(dots: false));
    await t.pumpAndSettle();
    expect(find.byType(PageDots), findsNothing);
  });
}
