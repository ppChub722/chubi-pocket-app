import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// TxRow's recurring / linked / status / dimmed extensions (K6) never change
/// the row height, and each marker renders.
void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      locale: const Locale('th'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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

  Future<double> height(WidgetTester t, Widget child) async {
    await pump(t, child);
    return t.getSize(find.byWidget(child)).height;
  }

  const lead = SizedBox(width: 36, height: 36);
  const status = AppChip(label: 'หยุดชั่วคราว', size: ChipSize.mini);

  TxRow marked() => TxRow(
    leading: lead,
    title: 'Netflix',
    amount: -419,
    walletLabel: 'กสิกร',
    category: 'บันเทิง',
    metaLeading: DueText(
      date: DateTime(2026, 10, 11),
      today: DateTime(2026, 10, 13),
      withDate: false,
    ),
    meta: const ['ทุกวันที่ 3'],
    recurring: true,
    progress: '3/12',
    linked: true,
    hasSplits: true,
    statusChip: status,
    dimmed: true,
  );

  testWidgets('every marker on = the same height as a plain row', (t) async {
    final plain = await height(
      t,
      const TxRow(
        leading: lead,
        title: 'Lunch',
        amount: -120,
        category: 'Food',
      ),
    );
    final withMarkers = await height(t, marked());
    expect(withMarkers, closeTo(plain, 0.01));
    // The skeleton still matches too.
    final skel = await height(t, const ListRowSkeleton());
    expect(skel, closeTo(withMarkers, 1));
  });

  testWidgets('markers only (no line-2 text) = the same height', (t) async {
    final plain = await height(
      t,
      const TxRow(leading: lead, title: 'Lunch', amount: -120, category: 'F'),
    );
    final onlyGlyphs = await height(
      t,
      const TxRow(
        leading: lead,
        title: 'Lunch',
        amount: -120,
        recurring: true,
        progress: '4/12',
        statusChip: status,
      ),
    );
    expect(onlyGlyphs, closeTo(plain, 0.01));
  });

  testWidgets('renders 🔁 + progress, 🔗, the status chip, dimmed', (t) async {
    await pump(t, marked());
    expect(find.byIcon(AppIcons.recurring), findsOneWidget);
    expect(find.text('3/12'), findsOneWidget);
    expect(find.byIcon(AppIcons.link), findsOneWidget);
    expect(find.byIcon(AppIcons.split), findsOneWidget);
    expect(find.text('หยุดชั่วคราว'), findsOneWidget);
    expect(find.text('เลยกำหนด 2 วัน'), findsOneWidget);
    expect(find.textContaining('ทุกวันที่ 3'), findsOneWidget);
    final fade = t.widget<Opacity>(
      find.ancestor(of: find.text('Netflix'), matching: find.byType(Opacity)),
    );
    expect(fade.opacity, lessThan(1));
  });

  testWidgets('defaults: no markers, no fade', (t) async {
    await pump(
      t,
      const TxRow(leading: lead, title: 'Lunch', amount: -120, category: 'F'),
    );
    expect(find.byIcon(AppIcons.scheduled), findsNothing);
    expect(find.byIcon(AppIcons.link), findsNothing);
    expect(
      find.ancestor(of: find.text('Lunch'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });
}
