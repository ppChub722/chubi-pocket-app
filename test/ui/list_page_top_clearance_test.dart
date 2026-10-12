import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(padding: EdgeInsets.only(top: 80)),
      child: Scaffold(body: child),
    ),
  );
  const empty = EmptyView(icon: Icons.inbox, title: 'e', message: 'm');
  Future<void> noop() async {}

  testWidgets('ListPageBody: header and rows start below the top bar', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        ListPageBody(
          loading: false,
          error: null,
          isEmpty: false,
          onRetry: noop,
          empty: empty,
          header: const [Text('header')],
          children: const [Text('row')],
        ),
      ),
    );
    expect(t.getTopLeft(find.text('header')).dy, greaterThanOrEqualTo(80));
    await t.pumpWidget(
      host(
        ListPageBody(
          loading: false,
          error: null,
          isEmpty: false,
          onRetry: noop,
          empty: empty,
          children: const [Text('row')],
        ),
      ),
    );
    expect(t.getTopLeft(find.text('row')).dy, greaterThanOrEqualTo(80));
  });

  testWidgets('TabbedListPageBody: tab bar below the bar, tabs not doubled', (
    t,
  ) async {
    final c = PageController();
    await t.pumpWidget(
      host(
        TabbedListPageBody<int>(
          tabs: const [
            AppTab(value: 0, label: 'one'),
            AppTab(value: 1, label: 'two'),
          ],
          selected: 0,
          onChanged: (_) {},
          controller: c,
          pageBuilder: (_, tab) => ListPageBody(
            loading: false,
            error: null,
            isEmpty: false,
            onRetry: noop,
            empty: empty,
            topInset: 0,
            children: [Text('row$tab')],
          ),
        ),
      ),
    );
    final tabTop = t.getTopLeft(find.text('one')).dy;
    expect(tabTop, greaterThanOrEqualTo(80));
    expect(tabTop, lessThan(120));
    // The page under the tab bar adds no second bar clearance.
    expect(t.getTopLeft(find.text('row0')).dy - tabTop, lessThan(60));
  });

  testWidgets(
    'rowDividers: row hairlines, header hairline, thick band between groups',
    (t) async {
      await t.pumpWidget(
        host(
          ListPageBody(
            loading: false,
            error: null,
            isEmpty: false,
            onRetry: noop,
            empty: empty,
            rowDividers: true,
            children: const [
              DateGroupHeader(label: 'Today'),
              Text('a'),
              Text('b'),
              DateGroupHeader(label: 'Yesterday'),
              Text('c'),
            ],
          ),
        ),
      );
      // header→row hairline ×2 + the a|b row hairline = 3 hairlines, and ONE thick
      // band between the two day groups.
      expect(find.byType(AppDivider), findsNWidgets(3));
      expect(
        find.byWidgetPredicate((w) => w is SizedBox && w.height == 8),
        findsOneWidget,
      );
    },
  );
}
