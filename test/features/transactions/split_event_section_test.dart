import 'package:chubi_pocket/features/transactions/presentation/widgets/split_event_section.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one "แบ่งรายการ" section (owner 2026-10-12): heading + one-line
/// description, a "แบ่งยอด" row and an "อีเวนต์" row, no separators inside;
/// collapsible (pending closed / quick create open) or always open (detail).
void main() {
  Future<void> pump(WidgetTester t, Widget section) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('th'),
      builder: (context, child) => AppUiConfig(child: child!),
      home: Scaffold(body: SingleChildScrollView(child: section)),
    ),
  );

  const splits = DetailRow(label: 'แบ่งยอด');

  testWidgets('always open: heading, description, both rows, no dividers', (
    t,
  ) async {
    await pump(
      t,
      const SplitEventSection(
        first: true,
        splits: splits,
        event: SplitEventSlot(),
      ),
    );
    expect(find.text('แบ่งรายการ'), findsOneWidget);
    expect(find.text('แบ่งยอดให้คนอื่น หรือใส่ในอีเวนต์'), findsOneWidget);
    expect(find.text('แบ่งยอด'), findsOneWidget);
    expect(find.text('อีเวนต์'), findsOneWidget);
    // The faint placeholder when no event is set.
    expect(find.text('ไม่ได้เลือก'), findsOneWidget);
    expect(find.byType(AppDivider), findsNothing);
    // Not collapsible: no chevron, tapping the heading changes nothing.
    await t.tap(find.text('แบ่งรายการ'));
    await t.pump();
    expect(find.text('อีเวนต์'), findsOneWidget);
  });

  testWidgets('collapsible + closed: one-line summary; tap opens, tap closes', (
    t,
  ) async {
    await pump(
      t,
      const SplitEventSection(
        first: true,
        collapsible: true,
        initiallyOpen: false,
        summary: 'แบ่ง 2 คน · ทริป',
        splits: splits,
        event: SplitEventSlot(name: 'ทริป'),
      ),
    );
    expect(find.text('แบ่ง 2 คน · ทริป'), findsOneWidget);
    expect(find.text('อีเวนต์'), findsNothing);
    expect(find.text('แบ่งยอดให้คนอื่น หรือใส่ในอีเวนต์'), findsNothing);

    await t.tap(find.text('แบ่งรายการ'));
    await t.pump();
    expect(find.text('อีเวนต์'), findsOneWidget);
    expect(find.text('แบ่งยอดให้คนอื่น หรือใส่ในอีเวนต์'), findsOneWidget);

    await t.tap(find.text('แบ่งรายการ'));
    await t.pump();
    expect(find.text('อีเวนต์'), findsNothing);
  });

  testWidgets('closed with nothing set says ไม่ได้ตั้ง', (t) async {
    await pump(
      t,
      const SplitEventSection(
        first: true,
        collapsible: true,
        initiallyOpen: false,
        splits: splits,
        event: SplitEventSlot(),
      ),
    );
    expect(find.text('ไม่ได้ตั้ง'), findsOneWidget);
  });

  testWidgets('quick create: collapsible but open by default', (t) async {
    await pump(
      t,
      const SplitEventSection(
        first: true,
        collapsible: true,
        splits: splits,
        event: SplitEventSlot(),
      ),
    );
    expect(find.text('อีเวนต์'), findsOneWidget);
  });
}
