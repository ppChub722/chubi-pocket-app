import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The debt person / list pieces (owner 2026-10-22, mocks DebtsList /
/// DebtPerson / DebtEntry) at 320 and 390 with long Thai words and big
/// amounts: nothing overflows, amounts stay at the end, the divider keeps
/// its lines, the share sheet hands back the edited text.
void main() {
  Future<void> pump(WidgetTester t, double width, Widget child) {
    t.view.physicalSize = Size(width * 3, 1400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    return t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ),
      ),
    );
  }

  const longName = 'ลี ทดสอบ ชื่อยาวมากจริงๆ นามสกุลก็ยาว';

  for (final width in [320.0, 390.0]) {
    testWidgets('at $width: the hero line, buttons, rows and divider fit', (
      t,
    ) async {
      var settled = 0;
      await pump(
        t,
        width,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DebtSentenceAmount(
              key: ValueKey('sentence'),
              sentence: 'รอจ่ายให้$longName',
              amount: Text('฿1,234,567.89', key: ValueKey('bigAmount')),
            ),
            const SizedBox(height: 8),
            DebtPersonActions(
              settleLabel: 'จ่ายคืน ฿1,234,567.89',
              onSettle: () => settled++,
              shareLabel: 'สรุปยอด',
              onShare: () {},
            ),
            const SizedBox(height: 8),
            const DebtEntryNote(
              sentence: 'รอรับจาก$longName',
              amount: Text('฿1,234,567.89'),
              paidLabel: 'จ่ายแล้ว',
            ),
            const SizedBox(height: 8),
            const DebtStatementRow(
              key: ValueKey('debtRow'),
              title: 'ค่าตั๋วคอนเสิร์ตรอบพิเศษที่ไปด้วยกันเมื่อเดือนก่อน',
              subtitle: '$longNameจ่ายแทน · จากกระเป๋าเงินสด',
              amount: Text('+฿1,234,567.89', key: ValueKey('rowAmount')),
              paidLabel: 'จ่ายแล้ว',
            ),
            const DebtStatementRow(
              title: 'ได้คืนจาก$longName',
              amount: Text('฿5,000'),
              repayment: true,
            ),
            const CycleDivider(
              key: ValueKey('divider'),
              label: 'เคลียร์ครบ 20 ส.ค. 2026 | ดูรอบก่อนหน้าทั้งหมด ▾',
            ),
            const PersonBalanceRow(
              key: ValueKey('balanceRow'),
              name: longName,
              level: PersonLevel.contact,
              net: -12345.5,
              owedToMeLabel: 'รอรับ',
              iOweLabel: 'รอจ่าย',
              settledLabel: 'ครบแล้ว',
              subtitle: 'ค่าตั๋วคอนเสิร์ตรอบพิเศษ | 20 ส.ค.',
              age: 'ค้าง 145 วัน',
              ageWarn: true,
            ),
          ],
        ),
      );
      expect(t.takeException(), isNull);
      final right = width - 16 + 0.5;
      // The big amount stays at the end of the hero line.
      expect(
        t.getRect(find.byKey(const ValueKey('bigAmount'))).right,
        lessThanOrEqualTo(right),
      );
      // Settle is the wider button; both in the column.
      final settle = t.getRect(find.byKey(const ValueKey('debtSettle')));
      final share = t.getRect(find.byKey(const ValueKey('debtShare')));
      expect(settle.width, greaterThan(share.width));
      expect(share.right, lessThanOrEqualTo(right));
      await t.tap(find.byKey(const ValueKey('debtSettle')));
      expect(settled, 1);
      // A row's amount ends at the row's padding; the title is to its left.
      final row = t.getRect(find.byKey(const ValueKey('debtRow')));
      final amount = t.getRect(find.byKey(const ValueKey('rowAmount')));
      expect(amount.right, closeTo(row.right - 12, 4));
      // The divider: a line left and right of the (wrapped) words.
      final words = t.getRect(find.byKey(const ValueKey('cycleDivider')));
      final divider = t.getRect(find.byKey(const ValueKey('divider')));
      expect(words.left - divider.left, greaterThanOrEqualTo(16));
      expect(divider.right - words.right, greaterThanOrEqualTo(16));
      // The age sits under the amount, warned.
      final age = t.widget<Text>(find.byKey(const ValueKey('personAge')));
      expect(age.style?.fontWeight, FontWeight.w700);
      expect(
        t.getRect(find.byKey(const ValueKey('personAge'))).right,
        lessThanOrEqualTo(right),
      );
    });

    testWidgets('at $width: the share sheet picks, edits, copies', (t) async {
      String? copied;
      String? shared;
      await pump(
        t,
        width,
        DebtShareSheet(
          variants: const [
            (label: 'รอบนี้', text: 'line one\nline two'),
            (label: 'ยอดคงเหลืออย่างเดียว', text: 'balance only'),
          ],
          fieldLabel: 'ข้อความ',
          copyLabel: 'คัดลอก',
          shareLabel: 'แชร์',
          onCopy: (s) => copied = s,
          onShare: (s) => shared = s,
        ),
      );
      expect(t.takeException(), isNull);
      await t.tap(find.byKey(const ValueKey('shareVariant1')));
      await t.pump();
      expect(find.text('balance only'), findsOneWidget);
      await t.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('shareText')),
          matching: find.byType(EditableText),
        ),
        'edited',
      );
      await t.tap(find.text('คัดลอก'));
      await t.tap(find.text('แชร์'));
      expect(copied, 'edited');
      expect(shared, 'edited');
    });
  }

  testWidgets('no settle → the summary button alone takes the row', (t) async {
    await pump(t, 390, DebtPersonActions(shareLabel: 'ทวง', onShare: () {}));
    expect(find.byKey(const ValueKey('debtSettle')), findsNothing);
    expect(
      t.getRect(find.byKey(const ValueKey('debtShare'))).width,
      closeTo(390 - 32, 0.5),
    );
  });
}
