import 'package:chubi_pocket/core/constants/app_icons.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget sheet) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('th'),
      home: Scaffold(body: sheet),
    ),
  );

  PickerSheet fruits({
    String? selected,
    bool loading = false,
    ApiException? error,
    VoidCallback? onRetry,
    VoidCallback? onCreate,
  }) => PickerSheet(
    title: 'เลือกผลไม้',
    searchable: true,
    loading: loading,
    error: error,
    onRetry: onRetry,
    footer: onCreate == null
        ? null
        : PickerCreateRow(label: 'สร้างใหม่', onTap: onCreate),
    builder: (context, q) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final f in const ['มะม่วง', 'ทุเรียน', 'มังคุด'])
          if (q.isEmpty || f.contains(q))
            PickerRow(title: f, selected: f == selected, onTap: () {}),
      ],
    ),
  );

  testWidgets('header + ✕, live search, the pick highlighted — no ✓', (
    t,
  ) async {
    await pump(t, fruits(selected: 'ทุเรียน'));
    expect(find.text('เลือกผลไม้'), findsOneWidget);
    expect(find.byIcon(AppIcons.close), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsNothing);
    final row = t.widget<PickerRow>(find.widgetWithText(PickerRow, 'ทุเรียน'));
    expect(row.selected, isTrue);

    await t.enterText(find.byType(TextField), 'มัง');
    await t.pump();
    expect(find.text('มังคุด'), findsOneWidget);
    expect(find.text('มะม่วง'), findsNothing);
  });

  testWidgets('loading → skeleton rows; error → retry', (t) async {
    await pump(t, fruits(loading: true));
    expect(find.text('มะม่วง'), findsNothing);
    expect(find.byType(SkeletonListTile), findsWidgets);

    var retried = false;
    await pump(
      t,
      fruits(
        error: const ApiException(code: 'NETWORK', message: 'ล่ม'),
        onRetry: () => retried = true,
      ),
    );
    expect(find.text('มะม่วง'), findsNothing);
    await t.tap(find.byType(FilledButton).last);
    expect(retried, isTrue);
  });

  testWidgets('the create row sits under the list', (t) async {
    var created = false;
    await pump(t, fruits(onCreate: () => created = true));
    await t.tap(find.text('สร้างใหม่'));
    expect(created, isTrue);
  });
}
