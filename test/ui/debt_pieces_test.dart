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

  const owed = 'ติดคุณ';
  const owe = 'คุณติด';
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

  group('PersonRow', () {
    testWidgets('name, caption, role chip; onTap fires', (t) async {
      var taps = 0;
      await pump(
        t,
        PersonRow(
          name: 'มาตาก',
          level: PersonLevel.linked,
          caption: 'ผูกบัญชีแล้ว',
          role: 'เจ้าของ',
          onTap: () => taps++,
        ),
      );
      expect(find.text('มาตาก'), findsOneWidget);
      expect(find.text('ผูกบัญชีแล้ว'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'เจ้าของ'), findsOneWidget);
      expect(find.byType(PersonLinkBadge), findsOneWidget);
      await t.tap(find.text('มาตาก'));
      expect(taps, 1);
    });

    testWidgets('pending fades the row', (t) async {
      await pump(
        t,
        const PersonRow(name: 'ต้น', level: PersonLevel.name, pending: true),
      );
      final fade = t.widget<Opacity>(
        find.ancestor(of: find.text('ต้น'), matching: find.byType(Opacity)),
      );
      expect(fade.opacity, lessThan(1));
    });

    testWidgets('not pending: no fade', (t) async {
      await pump(t, const PersonRow(name: 'ต้น', level: PersonLevel.name));
      expect(
        find.ancestor(of: find.text('ต้น'), matching: find.byType(Opacity)),
        findsNothing,
      );
    });
  });

  group('PersonBalanceRow', () {
    Widget row({bool selected = false, VoidCallback? onTap}) =>
        PersonBalanceRow(
          name: 'บี',
          level: PersonLevel.contact,
          net: -300,
          subtitle: 'ค้าง 2 รายการ',
          owedToMeLabel: owed,
          iOweLabel: owe,
          settledLabel: even,
          selected: selected,
          onTap: onTap,
        );

    Color? tintOf(WidgetTester t) => t
        .widget<Material>(
          find
              .ancestor(
                of: find.byType(ListRow),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;

    testWidgets('texts + the net at the end', (t) async {
      var taps = 0;
      await pump(t, row(onTap: () => taps++));
      // The name + the avatar's initials.
      expect(find.text('บี'), findsWidgets);
      expect(find.text('ค้าง 2 รายการ'), findsOneWidget);
      expect(find.text('฿300.00'), findsOneWidget);
      expect(find.text(owe), findsOneWidget);
      expect(find.byIcon(AppIcons.check), findsNothing);
      await t.tap(find.text('ค้าง 2 รายการ'));
      expect(taps, 1);
    });

    testWidgets('selected = the primary highlight tint, no ✓', (t) async {
      await pump(t, row());
      expect(tintOf(t), Colors.transparent);
      await pump(t, row(selected: true));
      final primary = Theme.of(
        t.element(find.text('ค้าง 2 รายการ')),
      ).colorScheme.primary;
      expect(tintOf(t), primary.withValues(alpha: 0.10));
      expect(find.byIcon(AppIcons.check), findsNothing);
    });
  });

  group('LedgerRow', () {
    testWidgets('paid: expense tint, positive amount, wallet + paid chips', (
      t,
    ) async {
      var taps = 0;
      await pump(
        t,
        LedgerRow(
          direction: LedgerDirection.paid,
          amount: -500,
          title: 'ฉันจ่ายให้มาตาก',
          dateLabel: '12 ต.ค.',
          walletLabel: 'กสิกร',
          paidLabel: 'จ่ายแล้ว',
          sourceLabel: 'ทริป',
          onTap: () => taps++,
        ),
      );
      expect(find.text('ฉันจ่ายให้มาตาก'), findsOneWidget);
      expect(find.text('12 ต.ค.'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'กสิกร'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'จ่ายแล้ว'), findsOneWidget);
      expect(find.text(' · ทริป'), findsOneWidget);
      expect(find.text('฿500.00'), findsOneWidget);
      expect(colorOf(t, '฿500.00'), colors.expense);
      expect(t.widget<IconTile>(find.byType(IconTile)).color, colors.expense);
      await t.tap(find.text('ฉันจ่ายให้มาตาก'));
      expect(taps, 1);
    });

    testWidgets('received: income tint, no chips without wallet / label', (
      t,
    ) async {
      await pump(
        t,
        const LedgerRow(
          direction: LedgerDirection.received,
          amount: 300,
          title: 'มาตากจ่ายให้ฉัน',
          dateLabel: '10 ต.ค.',
        ),
      );
      expect(find.byType(AppChip), findsNothing);
      expect(colorOf(t, '฿300.00'), colors.income);
      expect(t.widget<IconTile>(find.byType(IconTile)).color, colors.income);
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

  group('geometry', () {
    Future<double> height(WidgetTester t, Widget child) async {
      await pump(t, child);
      return t.getSize(find.byWidget(child)).height;
    }

    testWidgets('LedgerRow = TxRow height (with and without chips)', (t) async {
      final tx = await height(
        t,
        const TxRow(
          leading: SizedBox(width: 36, height: 36),
          title: 'Lunch',
          amount: -120,
          category: 'Food',
        ),
      );
      final plain = await height(
        t,
        const LedgerRow(
          direction: LedgerDirection.paid,
          amount: 120,
          title: 'Lunch',
          dateLabel: '12 Oct',
        ),
      );
      final chips = await height(
        t,
        const LedgerRow(
          direction: LedgerDirection.received,
          amount: 120,
          title: 'Lunch',
          dateLabel: '12 Oct',
          walletLabel: 'KBank',
          paidLabel: 'Paid',
          sourceLabel: 'Trip',
        ),
      );
      expect(plain, closeTo(tx, 1));
      expect(chips, closeTo(tx, 1));
    });

    testWidgets('PersonRow / PersonBalanceRow = ListRow height', (t) async {
      final list = await height(
        t,
        const ListRow(
          leading: SizedBox(width: 40, height: 40),
          title: 'Bee',
          subtitle: 'Contact',
        ),
      );
      final person = await height(
        t,
        const PersonRow(
          name: 'Bee',
          level: PersonLevel.linked,
          caption: 'Contact',
          role: 'Owner',
        ),
      );
      final balance = await height(
        t,
        const PersonBalanceRow(
          name: 'Bee',
          level: PersonLevel.contact,
          net: 1200,
          subtitle: '2 open',
          owedToMeLabel: 'owes you',
          iOweLabel: 'you owe',
          settledLabel: 'settled',
        ),
      );
      expect(person, closeTo(list, 1));
      expect(balance, closeTo(list, 1));
    });
  });
}
