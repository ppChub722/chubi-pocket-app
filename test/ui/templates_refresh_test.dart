import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pull-to-refresh is the DEFAULT in every template (owner 2026-10-12): every
/// page exposes a RefreshIndicator; a detail page in edit mode does not.
void main() {
  Future<void> noop() async {}
  const empty = EmptyView(icon: Icons.inbox, title: 'e', message: 'm');
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('ListPageBody has a RefreshIndicator', (t) async {
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
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('TabbedListPageBody: a RefreshIndicator per tab page', (t) async {
    await t.pumpWidget(
      host(
        TabbedListPageBody<int>(
          tabs: const [
            PpForgeTab(value: 0, label: 'one'),
            PpForgeTab(value: 1, label: 'two'),
          ],
          selected: 0,
          onChanged: (_) {},
          controller: PageController(),
          pageBuilder: (_, tab) => ListPageBody(
            loading: false,
            error: null,
            isEmpty: false,
            onRetry: noop,
            empty: empty,
            children: [Text('row$tab')],
          ),
        ),
      ),
    );
    expect(find.byType(RefreshIndicator), findsWidgets);
  });

  testWidgets('DashboardPageBody has a RefreshIndicator', (t) async {
    await t.pumpWidget(
      host(
        DashboardPageBody(
          loading: false,
          error: null,
          isEmpty: false,
          onRetry: noop,
          kpis: const [Text('k')],
        ),
      ),
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('DetailPageBody refreshes in view, not while editing', (t) async {
    Widget page({required bool busy}) => host(
      EditModeScope(
        busy: busy,
        child: DetailPageBody(
          onRefresh: noop,
          sections: [
            (first) => SectionCard(first: first, children: const [Text('a')]),
          ],
        ),
      ),
    );
    await t.pumpWidget(page(busy: false));
    expect(find.byType(RefreshIndicator), findsOneWidget);
    await t.pumpWidget(page(busy: true));
    expect(find.byType(RefreshIndicator), findsNothing);
  });
}
