import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _T { a, b }

/// The shared kit for the 0.3.1-10 debts + events pages: list paging with a
/// retry row, the tabbed detail template, the multi-select picker.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: ThemeData(
      extensions: [
        ThemeRegistry.byId(
          ThemeRegistry.defaultThemeId,
        ).colorsFor(Brightness.light),
      ],
    ),
    home: Scaffold(body: child),
  );

  List<Widget> rows(String p, int n) => [
    for (var i = 0; i < n; i++)
      SizedBox(height: 56, child: Text('$p ${i + 1}')),
  ];

  group('ListPageBody paging', () {
    testWidgets('a failed page: retry row at the end, rows stay, footer', (
      t,
    ) async {
      var retried = 0;
      await t.pumpWidget(
        host(
          ListPageBody(
            loading: false,
            error: null,
            isEmpty: false,
            onRetry: () async {},
            empty: const EmptyView.compact(message: 'none'),
            hasMore: true,
            loadMoreError: StateError('x'),
            onRetryMore: () => retried++,
            footer: const Text('the end'),
            children: rows('row', 2),
          ),
        ),
      );
      expect(find.text('row 1'), findsOneWidget);
      expect(find.byType(LoadMoreErrorRow), findsOneWidget);
      expect(find.text("Couldn't load more"), findsOneWidget);
      expect(find.byType(ListRowSkeleton), findsNothing);
      expect(find.text('the end'), findsOneWidget);
      await t.tap(find.text('Retry'));
      expect(retried, 1);
    });

    testWidgets('no load-more calls while the last page failed', (t) async {
      var asked = 0;
      Widget page({Object? err}) => host(
        ListPageBody(
          loading: false,
          error: null,
          isEmpty: false,
          onRetry: () async {},
          empty: const EmptyView.compact(message: 'none'),
          hasMore: true,
          loadMoreError: err,
          onLoadMore: () => asked++,
          children: rows('row', 30),
        ),
      );
      await t.pumpWidget(page(err: StateError('x')));
      await t.drag(find.byType(ListView), const Offset(0, -3000));
      await t.pumpAndSettle();
      expect(asked, 0);
      await t.pumpWidget(page());
      await t.drag(find.byType(ListView), const Offset(0, -300));
      await t.pumpAndSettle();
      expect(asked, greaterThan(0));
    });
  });

  group('TabbedDetailBody', () {
    Widget body({
      required _T tab,
      required ValueChanged<_T> onChanged,
      Future<void> Function()? onRefreshA,
      bool editing = false,
      List<double>? topPaddingSeen,
    }) => host(
      TabbedDetailBody<_T>(
        selected: tab,
        onChanged: onChanged,
        editing: editing,
        tabs: const [
          AppTab(value: _T.a, label: 'Tab A'),
          AppTab(value: _T.b, label: 'Tab B'),
        ],
        hero: const SizedBox(height: 120, child: Text('hero')),
        belowHero: const [Text('the button')],
        compactBar: const AppCompactHeroCard(title: Text('compact')),
        tabBuilder: (context, t) {
          topPaddingSeen?.add(MediaQuery.paddingOf(context).top);
          return ListPageBody(
            loading: false,
            error: null,
            isEmpty: false,
            onRetry: t == _T.a ? (onRefreshA ?? () async {}) : () async {},
            empty: const EmptyView.compact(message: 'none'),
            children: rows(t == _T.a ? 'A' : 'B', 20),
          );
        },
      ),
    );

    testWidgets('hero, below-hero block, tab bar, the first tab only', (
      t,
    ) async {
      await t.pumpWidget(body(tab: _T.a, onChanged: (_) {}));
      expect(find.text('hero'), findsOneWidget);
      expect(find.text('the button'), findsOneWidget);
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
      expect(find.text('A 1'), findsOneWidget);
      // Lazy: the other tab is not built until it shows.
      expect(find.text('B 1'), findsNothing);
    });

    testWidgets('tapping a tab switches the body', (t) async {
      var tab = _T.a;
      late StateSetter set;
      await t.pumpWidget(
        StatefulBuilder(
          builder: (context, s) {
            set = s;
            return body(tab: tab, onChanged: (v) => set(() => tab = v));
          },
        ),
      );
      await t.tap(find.text('Tab B'));
      await t.pumpAndSettle();
      expect(tab, _T.b);
      expect(find.text('B 1'), findsOneWidget);
    });

    testWidgets('the tab lists get no top-bar clearance of their own', (
      t,
    ) async {
      final seen = <double>[];
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 80)),
          child: body(tab: _T.a, onChanged: (_) {}, topPaddingSeen: seen),
        ),
      );
      expect(seen, isNotEmpty);
      expect(seen.every((p) => p == 0), isTrue);
    });

    testWidgets('pull-to-refresh on a tab runs that tab’s load', (t) async {
      var refreshed = 0;
      await t.pumpWidget(
        body(tab: _T.a, onChanged: (_) {}, onRefreshA: () async => refreshed++),
      );
      await t.fling(find.text('A 1'), const Offset(0, 500), 1000);
      await t.pumpAndSettle();
      expect(refreshed, 1);
    });

    testWidgets('edit mode: no tab bar, the tabs lock', (t) async {
      await t.pumpWidget(body(tab: _T.a, onChanged: (_) {}, editing: true));
      expect(find.text('Tab A'), findsNothing);
      expect(find.byType(LockedInEdit), findsOneWidget);
    });
  });

  group('multi-select picker', () {
    testWidgets('checked rows lead with a square check and tint', (t) async {
      await t.pumpWidget(
        host(
          Column(
            children: [
              PickerRow(title: 'Dinner', checked: true, onTap: () {}),
              PickerRow(title: 'Taxi', checked: false, onTap: () {}),
              PickerRow(title: 'Single', onTap: () {}),
            ],
          ),
        ),
      );
      final checks = t.widgetList<SelectCheck>(find.byType(SelectCheck));
      expect(checks.map((c) => c.value), [true, false]);
    });

    testWidgets('the confirm bar is off with nothing checked', (t) async {
      var confirmed = 0;
      Widget bar(VoidCallback? on) =>
          host(PickerConfirmBar(label: 'Add (0)', onPressed: on));
      await t.pumpWidget(bar(null));
      await t.tap(find.text('Add (0)'));
      expect(confirmed, 0);
      await t.pumpWidget(bar(() => confirmed++));
      await t.tap(find.text('Add (0)'));
      expect(confirmed, 1);
    });
  });
}
