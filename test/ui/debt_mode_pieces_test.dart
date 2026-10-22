import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quick create หนี้'s kit pieces (owner 2026-10-21, mock QuickCreateDebt) at
/// 320 and 390: the two chips, the three-row result box and the flow
/// caption never overflow; words left, values right; the chips switch.
void main() {
  Future<void> pump(WidgetTester t, double width, Widget child) {
    t.view.physicalSize = Size(width * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    return t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ),
      ),
    );
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('at $width: chips, a long result box, the caption fit', (
      t,
    ) async {
      bool? picked;
      await pump(
        t,
        width,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DebtModeChips(
              towardMe: false,
              settle: false,
              recordLabel: 'รอจ่าย',
              settleLabel: 'จ่ายคืน',
              onChanged: (s) => picked = s,
            ),
            const SizedBox(height: 8),
            const FlowCards(
              from: Text('กระเป๋าเงินสดสำหรับใช้จ่ายประจำวัน'),
              to: Text('ลี ทดสอบ ชื่อยาวมาก'),
              caption:
                  'จดว่าฉันต้องคืนลี ทดสอบ (ฉันยืมเงินลี ทดสอบเข้ากระเป๋า)',
            ),
            const SizedBox(height: 8),
            const DebtResultBox(
              nowLabel: 'ลี ทดสอบ ชื่อยาวมาก ตอนนี้',
              afterLabel: 'หลังบันทึก',
              before: 'รอจ่าย ฿1,234,567.89',
              after: 'รอรับ ฿9,876,543.21',
              walletLabel: 'กระเป๋า กระเป๋าเงินสดสำหรับใช้จ่ายประจำวัน',
              walletValue: '−฿1,234,567.89',
              warning: 'เกินยอดค้าง — หลังบันทึกจะกลายเป็น รอรับ ฿9,876,543.21',
            ),
          ],
        ),
      );
      expect(t.takeException(), isNull);
      final box = t.getRect(find.byKey(const ValueKey('debtResultBox')));
      expect(box.right, lessThanOrEqualTo(width - 16 + 0.5));
      // Words left, the value right, on each row.
      final label = t.getRect(find.text('หลังบันทึก'));
      final value = t.getRect(find.text('รอรับ ฿9,876,543.21'));
      expect(label.left, lessThan(value.left));
      expect(value.right, closeTo(box.right - 12, 4));
      expect(find.byKey(const ValueKey('flowCaption')), findsOneWidget);
      // The unpicked chip is the dashed one; a tap picks it.
      await t.tap(find.text('จ่ายคืน'));
      expect(picked, isTrue);
    });
  }

  testWidgets('the colour follows the direction', (t) async {
    await pump(
      t,
      390,
      const DebtModeChips(
        towardMe: true,
        settle: true,
        recordLabel: 'รอรับ',
        settleLabel: 'รับคืน',
        onChanged: null,
      ),
    );
    final ctx = t.element(find.byType(DebtModeChips));
    for (final chip in t.widgetList<AppChip>(find.byType(AppChip))) {
      expect(chip.color, debtStateColor(ctx, owedToMe: true));
      expect(chip.dashed, isFalse); // fixed: nothing to switch
    }
  });
}
