import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// K5 (popover title) and K8 (submits actions off while offline).
void main() {
  Widget app(Widget child, {bool offline = false}) => MaterialApp(
    theme: ThemeData(extensions: [sweetTheme.lightColors]),
    builder: (context, nav) =>
        ConnectionScope(offline: offline, reconnects: 0, child: nav!),
    home: Scaffold(body: Center(child: child)),
  );

  const options = [
    SheetOption(value: 'edit', label: 'Edit'),
    SheetOption(value: 'archive', label: 'Archive', submits: true),
  ];

  Widget menu({String? title, ValueChanged<String>? onSelected}) =>
      OptionMenuAnchor<String>(
        title: title,
        options: options,
        onSelected: onSelected ?? (_) {},
        builder: (context, toggle) =>
            TextButton(onPressed: toggle, child: const Text('open')),
      );

  MenuItemButton row(WidgetTester tester, String label) =>
      tester.widget<MenuItemButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(MenuItemButton),
        ),
      );

  group('popover title', () {
    testWidgets('OptionMenuAnchor shows the title above the options', (
      tester,
    ) async {
      await tester.pumpWidget(app(menu(title: 'Save how?')));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Save how?'), findsOneWidget);
      final titleY = tester.getCenter(find.text('Save how?')).dy;
      expect(titleY, lessThan(tester.getCenter(find.text('Edit')).dy));
    });

    testWidgets('no title → only the options', (tester) async {
      await tester.pumpWidget(app(menu()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Save how?'), findsNothing);
      // Nothing but the option rows in the menu.
      expect(find.byType(MenuItemButton), findsNWidgets(2));
    });

    testWidgets('MultiOptionMenuAnchor and PopoverAnchor take a title', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MultiOptionMenuAnchor<String>(
                title: 'Which ones?',
                options: options,
                selected: const {},
                onChanged: (_) {},
                builder: (context, toggle) =>
                    TextButton(onPressed: toggle, child: const Text('multi')),
              ),
              PopoverAnchor(
                title: 'Colour',
                builder: (context, toggle) =>
                    TextButton(onPressed: toggle, child: const Text('pop')),
                contentBuilder: (context, close) => const Text('content'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('multi'));
      await tester.pumpAndSettle();
      expect(find.text('Which ones?'), findsOneWidget);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await tester.tap(find.text('pop'));
      await tester.pumpAndSettle();
      expect(find.text('Colour'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });
  });

  group('offline submits', () {
    testWidgets('popover: a submits row is off offline, the rest stay', (
      tester,
    ) async {
      await tester.pumpWidget(app(menu(), offline: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(row(tester, 'Archive').onPressed, isNull);
      expect(row(tester, 'Edit').onPressed, isNotNull);
    });

    testWidgets('popover: a submits row works online', (tester) async {
      String? picked;
      await tester.pumpWidget(app(menu(onSelected: (v) => picked = v)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(row(tester, 'Archive').onPressed, isNotNull);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(picked, 'archive');
    });

    Widget bar() => ActionBar(
      actions: [
        ActionBarItem(label: 'Adjust', submits: true, onPressed: () {}),
        ActionBarItem(label: 'Entry', onPressed: () {}),
      ],
    );

    bool barEnabled(WidgetTester tester, String label) {
      final finder = find.widgetWithText(PpForgeButton, label);
      return tester
          .widget<PpForgeButton>(finder)
          .isEnabled(tester.element(finder));
    }

    testWidgets('ActionBar: a submits item is off offline only', (
      tester,
    ) async {
      await tester.pumpWidget(app(bar(), offline: true));
      expect(barEnabled(tester, 'Adjust'), isFalse);
      expect(barEnabled(tester, 'Entry'), isTrue);

      await tester.pumpWidget(app(bar()));
      expect(barEnabled(tester, 'Adjust'), isTrue);
      expect(barEnabled(tester, 'Entry'), isTrue);
    });

    Future<String?> openSheet(
      WidgetTester tester, {
      bool offline = false,
    }) async {
      String? result = 'unset';
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showOptionSheet<String>(
                context,
                title: 'Row',
                options: options,
              ),
              child: const Text('sheet'),
            ),
          ),
          offline: offline,
        ),
      );
      await tester.tap(find.text('sheet'));
      await tester.pumpAndSettle();
      PickerRow pickerRow(String label) =>
          tester.widget<PickerRow>(find.widgetWithText(PickerRow, label));
      expect(pickerRow('Edit').onTap, isNotNull);
      if (offline) {
        expect(pickerRow('Archive').onTap, isNull);
        await tester.tap(find.text('Archive'));
        await tester.pumpAndSettle();
        // Still open: the tap did nothing.
        expect(find.text('Row'), findsOneWidget);
        return result;
      }
      expect(pickerRow('Archive').onTap, isNotNull);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('option sheet: a submits row is off offline', (tester) async {
      expect(await openSheet(tester, offline: true), 'unset');
    });

    testWidgets('option sheet: a submits row works online', (tester) async {
      expect(await openSheet(tester), 'archive');
    });
  });
}
