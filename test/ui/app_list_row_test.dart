import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// AppListRow: line-2 markers and chips never change the row height; every
/// marker renders; actions never reach the row's onTap.
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
  const money = ListRowTrailing.value(MoneyText(-419, tone: MoneyTone.signed));

  AppListRow marked() => const AppListRow(
    leading: lead,
    title: 'Netflix',
    titleChips: [ListRowChip('กสิกร')],
    status: ListRowChip('หยุดชั่วคราว', tone: Tone.warning),
    line2: ListRowLine(
      lead: ListRowChip('อีก 3 วัน', tone: Tone.primary),
      icon: AppIcons.recurring,
      parts: ['ทุกเดือน', 'บันเทิง'],
      glyphs: [
        ListRowGlyph(AppIcons.progress, text: '3/12'),
        ListRowGlyph(AppIcons.link),
        ListRowGlyph(AppIcons.shared, text: '2'),
      ],
    ),
    trailing: money,
    dimmed: true,
  );

  testWidgets('every marker on = the same height as a plain row', (t) async {
    final plain = await height(
      t,
      const AppListRow(
        leading: lead,
        title: 'Lunch',
        line2: ListRowLine(parts: ['Food']),
        trailing: money,
      ),
    );
    final withMarkers = await height(t, marked());
    expect(withMarkers, closeTo(plain, 0.01));
    final skel = await height(t, const ListRowSkeleton());
    expect(skel, closeTo(withMarkers, 1));
  });

  testWidgets('a lead chip alone on line 2 = the same height', (t) async {
    final plain = await height(
      t,
      const AppListRow(
        leading: lead,
        title: 'Lunch',
        line2: ListRowLine(parts: ['Food']),
      ),
    );
    final chipOnly = await height(
      t,
      const AppListRow(
        leading: lead,
        title: 'Lunch',
        line2: ListRowLine(lead: ListRowChip('SMS', tone: Tone.info)),
      ),
    );
    expect(chipOnly, closeTo(plain, 0.01));
  });

  testWidgets('renders ↻ ⏲ 🔗 👥, chips, parts and the fade', (t) async {
    await pump(t, marked());
    expect(find.byIcon(AppIcons.recurring), findsOneWidget);
    expect(find.byIcon(AppIcons.progress), findsOneWidget);
    expect(find.text('3/12'), findsOneWidget);
    expect(find.byIcon(AppIcons.link), findsOneWidget);
    expect(find.byIcon(AppIcons.shared), findsOneWidget);
    expect(find.text('หยุดชั่วคราว'), findsOneWidget);
    expect(find.text('อีก 3 วัน'), findsOneWidget);
    expect(find.text('กสิกร'), findsOneWidget);
    expect(find.textContaining('ทุกเดือน | บันเทิง'), findsOneWidget);
    final fade = t.widget<Opacity>(
      find.ancestor(of: find.text('Netflix'), matching: find.byType(Opacity)),
    );
    expect(fade.opacity, lessThan(1));
  });

  testWidgets('every chip is a mini AppChip', (t) async {
    await pump(t, marked());
    final chips = t.widgetList<AppChip>(find.byType(AppChip)).toList();
    expect(chips, hasLength(3));
    for (final c in chips) {
      expect(c.maxWidth, AppListRow.chipMaxWidth);
    }
  });

  testWidgets('defaults: no markers, no fade, no check', (t) async {
    await pump(t, const AppListRow(leading: lead, title: 'Lunch'));
    expect(find.byIcon(AppIcons.recurring), findsNothing);
    expect(find.byType(SelectCheck), findsNothing);
    expect(
      find.ancestor(of: find.text('Lunch'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('an action never reaches onTap; the row does', (t) async {
    var row = 0;
    var action = 0;
    await pump(
      t,
      AppListRow(
        leading: lead,
        title: 'Spotify',
        actions: [ListRowAction.button(AppIcons.check, onTap: () => action++)],
        onTap: () => row++,
      ),
    );
    await t.tap(find.byIcon(AppIcons.check));
    expect((row, action), (0, 1));
    await t.tap(find.text('Spotify'));
    expect((row, action), (1, 1));
  });

  testWidgets('checked shows the check; onCheck falls back to onTap', (
    t,
  ) async {
    var taps = 0;
    await pump(
      t,
      AppListRow(
        leading: lead,
        title: 'Pick me',
        checked: false,
        onTap: () => taps++,
      ),
    );
    expect(find.byType(SelectCheck), findsOneWidget);
    await t.tap(find.byType(SelectCheck));
    expect(taps, 1);
  });

  testWidgets('trailing caption and alert render', (t) async {
    await pump(
      t,
      const AppListRow(
        leading: lead,
        title: 'ค่าไฟ',
        trailing: ListRowTrailing.text(
          'รอใส่ยอด',
          tone: Tone.warning,
          caption: 'พรุ่งนี้',
        ),
        alert: ListRowAlert('ยังไม่ได้เลือกหมวด'),
      ),
    );
    expect(find.text('รอใส่ยอด'), findsOneWidget);
    expect(find.text('พรุ่งนี้'), findsOneWidget);
    expect(find.text('ยังไม่ได้เลือกหมวด'), findsOneWidget);
  });
}
