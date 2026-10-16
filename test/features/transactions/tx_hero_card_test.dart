import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController amount;
  late TextEditingController note;

  setUp(() {
    amount = TextEditingController();
    note = TextEditingController();
  });

  tearDown(() {
    amount.dispose();
    note.dispose();
  });

  Future<void> pump(WidgetTester t, Widget card) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('th'),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: card),
      ),
    ),
  );

  testWidgets('swiping steps through the types, without wrapping', (t) async {
    var type = TransactionType.expense;
    await pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => TxHeroCard(
          type: type,
          onTypeChanged: (v) => setState(() => type = v),
          amount: amount,
          title: note,
          dateLabel: 'วันนี้',
        ),
      ),
    );
    final card = find.byType(TxHeroCard);
    await t.fling(card, const Offset(-300, 0), 1500);
    await t.pumpAndSettle();
    expect(type, TransactionType.income);
    await t.fling(card, const Offset(-300, 0), 1500);
    await t.pumpAndSettle();
    expect(type, TransactionType.transfer);
    await t.fling(card, const Offset(-300, 0), 1500);
    await t.pumpAndSettle();
    expect(type, TransactionType.transfer);
    await t.fling(card, const Offset(300, 0), 1500);
    await t.pumpAndSettle();
    expect(type, TransactionType.income);
  });

  testWidgets('a chip tap picks that type; no transfer when not allowed', (
    t,
  ) async {
    TransactionType? picked;
    await pump(
      t,
      TxHeroCard(
        type: TransactionType.expense,
        allowTransfer: false,
        onTypeChanged: (v) => picked = v,
        amount: amount,
        title: note,
        dateLabel: 'วันนี้',
      ),
    );
    // Expense + income only (no transfer).
    expect(find.widgetWithText(PpForgeChip, 'รายจ่าย'), findsOneWidget);
    expect(find.widgetWithText(PpForgeChip, 'รายรับ'), findsOneWidget);
    expect(find.text('โอนเงิน'), findsNothing);
    await t.tap(find.text('รายรับ'));
    expect(picked, TransactionType.income);
  });

  testWidgets('a locked type shows only its own chip', (t) async {
    await pump(
      t,
      TxHeroCard(
        type: TransactionType.income,
        amount: amount,
        title: note,
        dateLabel: 'วันนี้',
      ),
    );
    expect(find.widgetWithText(PpForgeChip, 'รายรับ'), findsOneWidget);
    expect(find.text('รายจ่าย'), findsNothing);
    await t.fling(find.byType(TxHeroCard), const Offset(-300, 0), 1500);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('view mode: read-only fields, ✏️ and long-press enter edit', (
    t,
  ) async {
    var edits = 0;
    FocusNode? focused;
    final noteFocus = FocusNode();
    addTearDown(noteFocus.dispose);
    note.text = 'ข้าวมันไก่';
    await pump(
      t,
      TxHeroCard(
        type: TransactionType.expense,
        amount: amount,
        title: note,
        titleFocus: noteFocus,
        dateLabel: 'วันนี้',
        editing: false,
        onEdit: () => edits++,
        onLongPressField: (f) => focused = f,
      ),
    );
    for (final f in t.widgetList<TextField>(find.byType(TextField))) {
      expect(f.readOnly, isTrue);
    }
    await t.tap(find.byTooltip('แก้ไข'));
    expect(edits, 1);
    // The field absorbs pointers in view mode — the wrapper gets it.
    await t.longPress(find.text('ข้าวมันไก่'), warnIfMissed: false);
    expect(focused, noteFocus);
  });

  testWidgets('inline view mode: type chip, date + ✏️, amount, then footer', (
    t,
  ) async {
    amount.text = '182';
    await pump(
      t,
      TxHeroCard(
        type: TransactionType.expense,
        amount: amount,
        title: note,
        dateLabel: 'วันนี้',
        editing: false,
        inline: true,
        onEdit: () {},
        footer: const Text('chips'),
      ),
    );
    // Row 1: the type chip on the left, the date then ✏️ top-right; row 2:
    // the amount; row 3: the footer.
    final edit = t.getTopLeft(find.byTooltip('แก้ไข'));
    final date = t.getTopLeft(find.text('วันนี้'));
    final type = t.getTopLeft(find.text('รายจ่าย'));
    expect(type.dx, lessThan(date.dx));
    expect(date.dx, lessThan(edit.dx));
    expect(edit.dy, lessThan(t.getTopLeft(find.text('182')).dy));
    expect(
      t.getTopLeft(find.text('chips')).dy,
      greaterThan(t.getTopLeft(find.text('182')).dy),
    );
    // An empty description shows nothing in view mode.
    expect(find.byType(TextField), findsOneWidget); // just the amount
    // Only its own type, and no 🔒 in view (owner 2026-10-10).
    expect(find.widgetWithText(PpForgeChip, 'รายจ่าย'), findsOneWidget);
    expect(find.text('รายรับ'), findsNothing);
    expect(find.byIcon(PpForgeIcons.lock), findsNothing);
    expect(find.text('฿'), findsOneWidget); // no −/+ before it
    expect(find.text('182'), findsOneWidget);
  });

  testWidgets('inline edit: the whole amount cell focuses the amount', (
    t,
  ) async {
    final amountFocus = FocusNode();
    addTearDown(amountFocus.dispose);
    // Two lines of description — the row is taller than the amount.
    note.text = List.filled(12, 'ข้าวมันไก่').join(' ');
    await pump(
      t,
      TxHeroCard(
        type: TransactionType.expense,
        amount: amount,
        title: note,
        amountFocus: amountFocus,
        dateLabel: 'วันนี้',
        inline: true,
      ),
    );
    final symbol = t.getRect(find.text('฿'));
    final titleTop = t.getTopLeft(find.text(note.text)).dy;
    // Token geometry: the description starts level with the ฿ (shared baseline).
    expect(titleTop, lessThan(symbol.bottom));
    // Left of the ฿, level with the description's first line: empty space
    // in the amount's half of the row.
    await t.tapAt(Offset(symbol.left - 24, titleTop + 2));
    await t.pump();
    expect(amountFocus.hasFocus, isTrue);
  });

  testWidgets('a locked type in edit mode shows the 🔒 chip', (t) async {
    await pump(
      t,
      TxHeroCard(
        type: TransactionType.income,
        amount: amount,
        title: note,
        dateLabel: 'วันนี้',
        inline: true,
      ),
    );
    expect(find.widgetWithText(PpForgeChip, 'รายรับ'), findsOneWidget);
    expect(find.text('รายจ่าย'), findsNothing);
    expect(find.byIcon(PpForgeIcons.lock), findsOneWidget);
    expect(find.byType(Tooltip), findsWidgets);
  });

  testWidgets('description and amount underlines share one bottom line', (
    t,
  ) async {
    amount.text = '1,250';
    note.text = 'ข้าวมันไก่';
    final key = GlobalKey();
    await pump(
      t,
      RepaintBoundary(
        key: key,
        child: TxHeroCard(
          type: TransactionType.expense,
          amount: amount,
          title: note,
          dateLabel: 'วันนี้',
          inline: true,
        ),
      ),
    );
    // The labels (คำอธิบาย / จำนวนเงิน) sit ABOVE the inputs in edit mode.
    expect(find.text('คำอธิบาย'), findsOneWidget);
    expect(find.text('จำนวนเงิน'), findsOneWidget);
    // Measure the DRAWN underlines (pixels), not widget rects: a field's
    // widget bottom can sit below its underline.
    final fields = find.byType(PpForgeInput);
    expect(fields, findsNWidgets(2));
    final image = await t.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return b.toImage(pixelRatio: 1);
    });
    final data = (await t.runAsync(() => image!.toByteData()))!;
    final outline = Theme.of(
      t.element(find.byType(TxHeroCard)),
    ).colorScheme.outline;
    int lowestUnderline(Finder field) {
      final r = t.getRect(field);
      final x = (r.left + 12).round();
      var hit = -1;
      for (
        var y = r.top.round();
        y < r.bottom.round() + 4 && y < image!.height;
        y++
      ) {
        final o = (y * image.width + x) * 4;
        final c = Color.fromARGB(
          data.getUint8(o + 3),
          data.getUint8(o),
          data.getUint8(o + 1),
          data.getUint8(o + 2),
        );
        if (c.toARGB32() == outline.toARGB32()) hit = y;
      }
      return hit;
    }

    final titleLine = lowestUnderline(fields.at(0));
    final amountLine = lowestUnderline(fields.at(1));
    expect(
      titleLine,
      greaterThan(0),
      reason: 'description underline not drawn',
    );
    expect(amountLine, greaterThan(0), reason: 'amount underline not drawn');
    expect(titleLine, amountLine, reason: 'underlines must share one y');
  });
}
