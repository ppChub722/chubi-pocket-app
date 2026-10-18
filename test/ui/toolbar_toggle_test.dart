import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);
  Widget host(ToolbarToggleState s, TextEditingController c, bool filtered) =>
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ToolbarToggleButton(state: s, filtered: filtered),
                ListToolbar(collapse: s, searchController: c),
              ],
            ),
          ),
        ),
      );

  testWidgets('hidden by default; 🔍 opens the toolbar; dot when filtered', (
    t,
  ) async {
    final s = ToolbarToggleState.local();
    final c = TextEditingController();
    await t.pumpWidget(host(s, c, true));
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('cardActionDot')), findsOneWidget);
    await t.tap(find.byType(CardActionButton));
    await t.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const ValueKey('cardActionDot')), findsNothing);
  });

  testWidgets('a detail hero ✏️ is the same CardActionButton slot', (t) async {
    var tapped = false;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: HeaderCard(
            leading: const SizedBox(width: 40, height: 40),
            title: const Text('Name'),
            onEdit: () => tapped = true,
          ),
        ),
      ),
    );
    final edit = find.byType(CardActionButton);
    expect(edit, findsOneWidget);
    expect(t.getSize(edit).width, ControlSizes.fallback.control);
    await t.tap(edit);
    expect(tapped, isTrue);
  });

  test('ToolbarToggleState.of remembers per key', () {
    ToolbarToggleState.resetAll();
    final a = ToolbarToggleState.of('p')..toggle();
    expect(ToolbarToggleState.of('p').value, isTrue);
    expect(identical(a, ToolbarToggleState.of('p')), isTrue);
    ToolbarToggleState.resetAll();
  });

  testWidgets('ProgressRow draws the pace marker only when given', (t) async {
    Future<void> pump(double? m) => t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(body: ProgressRow(value: 0.4, marker: m)),
      ),
    );
    await pump(null);
    expect(find.byKey(const ValueKey('progressMarker')), findsNothing);
    await pump(0.5);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('progressMarker')), findsOneWidget);
  });
}
