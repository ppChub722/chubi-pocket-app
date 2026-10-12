import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A skeleton and the real layout share their main geometry (heights), so
/// nothing jumps when the data arrives (owner 2026-10-12).
void main() {
  Future<double> height(WidgetTester t, Widget child) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            ThemeRegistry.byId(
              ThemeRegistry.defaultThemeId,
            ).colorsFor(Brightness.light),
          ],
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 400, child: Column(children: [child])),
          ),
        ),
      ),
    );
    return t.getSize(find.byWidget(child)).height;
  }

  testWidgets('list row: skeleton = real transaction row', (t) async {
    final real = await height(
      t,
      const TxRow(
        leading: SizedBox(width: 36, height: 36),
        title: 'Lunch',
        amount: -120,
        category: 'Food',
      ),
    );
    final skel = await height(t, const ListRowSkeleton());
    expect(skel, closeTo(real, 1));
  });

  testWidgets('detail row: skeleton = real DetailRow', (t) async {
    final real = await height(
      t,
      const DetailRow(label: 'Currency', trailing: Text('THB')),
    );
    final skel = await height(t, const DetailRowSkeleton());
    expect(skel, closeTo(real, 1));
  });

  testWidgets('hero: skeleton = real HeaderCard (chips · name · description)', (
    t,
  ) async {
    final real = await height(
      t,
      HeaderCard(
        topRow: [AppChip(label: 'Status', selected: true, onTap: () {})],
        leading: const SizedBox(width: 52, height: 52),
        title: const Text('Name'),
        description: const Text('Description', maxLines: 1),
      ),
    );
    final skel = await height(t, const HeroSkeleton());
    expect(skel, closeTo(real, 2));
  });

  testWidgets('headed section: skeleton = real SectionCard', (t) async {
    final real = await height(
      t,
      const SectionCard(
        first: true,
        title: 'Details',
        description: 'What it is.',
        children: [
          DetailRow(label: 'A', trailing: Text('1')),
          DetailRow(label: 'B', trailing: Text('2')),
        ],
      ),
    );
    final skel = await height(t, const SectionSkeleton(rows: 2, first: true));
    expect(skel, closeTo(real, 2));
  });

  testWidgets('toolbar: skeleton = real ListToolbar', (t) async {
    final real = await height(
      t,
      ListToolbar(
        searchController: TextEditingController(),
        onSearchChanged: (_) {},
        chips: const [AppChip(label: 'Filters')],
      ),
    );
    final skel = await height(t, const ListToolbarSkeleton());
    expect(skel, closeTo(real, 2));
  });

  testWidgets('dashboard: skeleton slots add up to the real body', (t) async {
    Future<double> extent(Widget body) async {
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              ThemeRegistry.byId(
                ThemeRegistry.defaultThemeId,
              ).colorsFor(Brightness.light),
            ],
          ),
          home: SizedBox(height: 300, child: Scaffold(body: body)),
        ),
      );
      final s = t.state<ScrollableState>(find.byType(Scrollable).first);
      return s.position.maxScrollExtent;
    }

    Future<void> noop() async {}
    const Widget hole = SizedBox.shrink();
    final real = await extent(
      DashboardPageBody(
        loading: false,
        error: null,
        isEmpty: false,
        onRetry: noop,
        topInset: 0,
        snapshot: const [SizedBox(height: 110)],
        period: const SizedBox(height: DashboardPageSkeleton.periodHeight),
        kpis: const [SizedBox(height: 90)],
        charts: const [SizedBox(height: 160), SizedBox(height: 140)],
        tiles: const SizedBox(height: 176),
      ),
    );
    final skel = await extent(
      const DashboardPageSkeleton(padding: EdgeInsets.fromLTRB(16, 0, 16, 96)),
    );
    expect(hole, isNotNull);
    expect(skel, closeTo(real, 1));
  });
}
