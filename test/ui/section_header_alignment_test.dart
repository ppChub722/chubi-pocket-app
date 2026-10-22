import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A SectionHeader's trailing (buttons or text) ends flush with the row card
/// below it, at any title length (owner 2026-10-21: the recurring list's 🔍 / +
/// and its group totals ended ~46 px short).
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Future<void> pump(WidgetTester t, double width, String title) async {
    t.view.physicalSize = Size(width, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: ListPageBody(
            loading: false,
            error: null,
            isEmpty: false,
            onRetry: () async {},
            empty: const EmptyView.compact(message: 'none'),
            children: [
              SectionHeader(
                key: const ValueKey('head'),
                title: title,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CardActionButton(icon: AppIcons.search, onTap: () {}),
                    const SizedBox(width: AppSpacing.sm),
                    CardActionButton(
                      key: const ValueKey('add'),
                      icon: AppIcons.add,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SectionHeader(
                title: title,
                count: 1,
                trailing: const AppText(
                  '฿3,023/mo | ฿36,276/yr',
                  key: ValueKey('totals'),
                  role: AppTextRole.caption,
                ),
              ),
              const SectionCard(
                key: ValueKey('card'),
                children: [ListTile(title: Text('Netflix'))],
              ),
            ],
          ),
        ),
      ),
    );
  }

  for (final (width, title) in [
    (412.0, 'All recurring'),
    (360.0, 'Subscriptions'),
    (412.0, 'A very long section title that has to ellipsize somewhere'),
  ]) {
    testWidgets('width $width, "$title": trailing edges == the card edge', (
      t,
    ) async {
      await pump(t, width, title);
      expect(t.takeException(), isNull); // no overflow
      final card = t.getRect(find.byKey(const ValueKey('card')));
      final add = t.getRect(find.byKey(const ValueKey('add')));
      final totals = t.getRect(find.byKey(const ValueKey('totals')));
      expect(add.right, card.right);
      expect(totals.right, card.right);
      // The title keeps its indent inside the gutter.
      final head = t.getRect(find.byKey(const ValueKey('head')));
      expect(head.left, card.left);
    });
  }
}
