import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The debts rework kit pieces (FE-CORE, 2026-10-13): texts, tints by sign /
/// direction from the theme tokens, the picker highlight, taps, the sort
/// popover.
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [colors]),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: Column(children: [child])),
        ),
      ),
    ),
  );

  Color? colorOf(WidgetTester t, String text) =>
      t.widget<Text>(find.text(text)).style?.color;

  const owed = 'รอรับ';
  const owe = 'รอจ่าย';
  const even = 'หายกัน';

  NetBalance net(num amount, {NetBalanceSize size = NetBalanceSize.row}) =>
      NetBalance(
        amount: amount,
        size: size,
        owedToMeLabel: owed,
        iOweLabel: owe,
        settledLabel: even,
      );

  group('NetBalance', () {
    testWidgets('> 0: income colour + owed-to-me caption', (t) async {
      await pump(t, net(1200));
      expect(find.text('฿1,200.00'), findsOneWidget);
      expect(find.text(owed), findsOneWidget);
      expect(colorOf(t, '฿1,200.00'), colors.income);
    });

    testWidgets('< 0: expense colour, shown positive + I-owe caption', (
      t,
    ) async {
      await pump(t, net(-450.5, size: NetBalanceSize.hero));
      expect(find.text('฿450.50'), findsOneWidget);
      expect(find.text(owe), findsOneWidget);
      expect(colorOf(t, '฿450.50'), colors.expense);
    });

    testWidgets('0: the settled caption only, muted, no amount', (t) async {
      await pump(t, net(0));
      expect(find.text(even), findsOneWidget);
      expect(find.byType(MoneyText), findsNothing);
      final scheme = Theme.of(t.element(find.text(even))).colorScheme;
      expect(colorOf(t, even), scheme.onSurfaceVariant);
    });
  });

  group('debt hero pieces', () {
    testWidgets('DebtAmountLine: pill + coloured amount; settled = word', (
      t,
    ) async {
      await pump(
        t,
        const DebtAmountLine(
          net: 1189.67,
          owedToMeLabel: 'รอรับ',
          iOweLabel: 'รอจ่าย',
          settledLabel: even,
        ),
      );
      expect(find.text('รอรับ'), findsOneWidget);
      expect(colorOf(t, '฿1,189.67'), colors.income);
      await pump(
        t,
        const DebtAmountLine(
          net: -50,
          owedToMeLabel: 'รอรับ',
          iOweLabel: 'รอจ่าย',
          settledLabel: even,
        ),
      );
      expect(find.text('รอจ่าย'), findsOneWidget);
      expect(colorOf(t, '฿50.00'), colors.expense);
      await pump(
        t,
        const DebtAmountLine(
          net: 0,
          owedToMeLabel: 'รอรับ',
          iOweLabel: 'รอจ่าย',
          settledLabel: even,
        ),
      );
      expect(find.text(even), findsOneWidget);
      expect(find.byType(AppChip), findsNothing);
    });

    testWidgets(
      'DebtSummaryMessageBox: prefilled, edits go out, new text wins',
      (t) async {
        final out = <String>[];
        Widget box(String text) => DebtSummaryMessageBox(
          text: text,
          label: 'ข้อความ',
          copyLabel: 'คัดลอก',
          shareLabel: 'แชร์',
          onCopy: (v) => out.add('copy:$v'),
          onShare: (v) => out.add('share:$v'),
        );
        await pump(t, box('hello'));
        expect(find.text('hello'), findsOneWidget);
        await t.enterText(
          find.byKey(const ValueKey('debtSummaryMessage')),
          'hi',
        );
        await t.tap(find.text('คัดลอก'));
        await t.tap(find.text('แชร์'));
        expect(out, ['copy:hi', 'share:hi']);
        await pump(t, box('fresh'));
        expect(find.text('fresh'), findsOneWidget);
      },
    );
  });

  group('SortChip', () {
    testWidgets('shows the current label; the popover picks', (t) async {
      String? picked;
      await pump(
        t,
        SortChip<String>(
          value: 'old',
          options: const [
            SortOption('new', 'ใหม่สุด'),
            SortOption('old', 'เก่าสุด'),
          ],
          onChanged: (v) => picked = v,
        ),
      );
      expect(find.text('เก่าสุด'), findsOneWidget);
      expect(find.text('ใหม่สุด'), findsNothing);
      expect(find.byIcon(AppIcons.sort), findsOneWidget);
      expect(find.byIcon(AppIcons.dropdown), findsOneWidget);

      await t.tap(find.text('เก่าสุด'));
      await t.pumpAndSettle();
      expect(find.text('ใหม่สุด'), findsOneWidget);
      expect(find.byIcon(AppIcons.check), findsNothing);
      await t.tap(find.text('ใหม่สุด'));
      await t.pumpAndSettle();
      expect(picked, 'new');
    });

    testWidgets('follows the ChipSizeScope (28 in a toolbar)', (t) async {
      await pump(
        t,
        ChipSizeScope(
          size: ChipSize.chip,
          child: SortChip<int>(
            value: 1,
            options: const [SortOption(1, 'A')],
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        t.getSize(find.byType(AppChip)).height,
        closeTo(ControlSizes.fallback.chip, 1),
      );
    });
  });
}
