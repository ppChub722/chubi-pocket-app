import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/atoms/dashed_rect_border.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('th'),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  /// Every content combination the app's chips need, at [size].
  List<Widget> variants(ChipSize size, {VoidCallback? onRemove}) => [
    PpForgeChip(label: 'ทั้งหมด', size: size),
    PpForgeChip(label: 'ทั้งหมด', size: size, selected: true),
    PpForgeChip(label: 'อาหาร', icon: PpForgeIcons.category, size: size),
    PpForgeChip(label: 'ใช้งาน', dot: true, selected: true, size: size),
    PpForgeChip(
      label: 'สถานะ',
      trailing: PpForgeChipTrailing.dropdown,
      size: size,
      onTap: () {},
    ),
    PpForgeChip(
      label: 'กระเป๋า',
      trailing: PpForgeChipTrailing.remove,
      onRemove: onRemove ?? () {},
      size: size,
    ),
    PpForgeChip(
      label: 'โอนเงิน',
      icon: PpForgeIcons.transfer,
      trailing: PpForgeChipTrailing.lock,
      size: size,
    ),
    PpForgeChip(
      label: 'สี',
      trailing: PpForgeChipTrailing.count,
      count: 12,
      size: size,
    ),
    PpForgeChip(
      label: 'ลี',
      leading: const UserAvatar(displayName: 'ลี'),
      size: size,
    ),
    PpForgeChip(label: 'รายจ่าย', icon: PpForgeIcons.expense, size: size),
    PpForgeChip(label: 'ปิด', enabled: false, size: size),
  ];

  for (final size in ChipSize.values) {
    testWidgets('every variant is ${size.height} high at ${size.name}', (
      t,
    ) async {
      final keys = <Key>[];
      final chips = [
        for (final (i, c) in variants(size).indexed)
          KeyedSubtree(key: Key('v$i'), child: c),
      ];
      keys.addAll(chips.map((c) => c.key!));
      await pump(
        t,
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: chips,
        ),
      );
      for (final k in keys) {
        expect(t.getSize(find.byKey(k)).height, size.height, reason: '$k');
      }
    });
  }

  testWidgets('selected tints border + fill in its colour; unselected grey', (
    t,
  ) async {
    await pump(
      t,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PpForgeChip(
            label: 'on',
            tone: PpForgeChipTone.danger,
            selected: true,
          ),
          PpForgeChip(label: 'off', tone: PpForgeChipTone.danger),
        ],
      ),
    );
    Material shell(String label) => t.widget<Material>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first,
    );
    final expense = sweetTheme.lightColors.expense;
    final on = shell('on');
    final off = shell('off');
    expect((on.shape! as StadiumBorder).side.color, expense);
    expect(on.color, expense.withValues(alpha: 0.12));
    expect((off.shape! as StadiumBorder).side.color, isNot(expense));
    expect(off.color, Colors.transparent);
  });

  testWidgets('✕ with no onTap: tapping the chip removes', (t) async {
    var removed = 0;
    await pump(
      t,
      PpForgeChip(
        label: 'กระเป๋า',
        trailing: PpForgeChipTrailing.remove,
        onRemove: () => removed++,
      ),
    );
    await t.tap(find.text('กระเป๋า'));
    expect(removed, 1);
  });

  testWidgets('✕ beside an onTap: each does its own thing', (t) async {
    var tapped = 0;
    var removed = 0;
    await pump(
      t,
      PpForgeChip(
        label: 'กระเป๋า',
        trailing: PpForgeChipTrailing.remove,
        onTap: () => tapped++,
        onRemove: () => removed++,
      ),
    );
    await t.tap(find.byIcon(PpForgeIcons.close));
    await t.tap(find.text('กระเป๋า'));
    expect((tapped, removed), (1, 1));
  });

  testWidgets('disabled ignores taps', (t) async {
    var tapped = 0;
    await pump(
      t,
      PpForgeChip(label: 'ปิด', enabled: false, onTap: () => tapped++),
    );
    await t.tap(find.text('ปิด'), warnIfMissed: false);
    expect(tapped, 0);
    expect(find.byType(Opacity), findsOneWidget);
  });

  testWidgets('count shows the number; lock shows 🔒', (t) async {
    await pump(
      t,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PpForgeChip(
            label: 'สี',
            trailing: PpForgeChipTrailing.count,
            count: 7,
          ),
          PpForgeChip(label: 'ประเภท', trailing: PpForgeChipTrailing.lock),
        ],
      ),
    );
    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(PpForgeIcons.lock), findsOneWidget);
  });

  testWidgets('a short interactive chip answers taps in a 44 band', (t) async {
    var taps = 0;
    await pump(
      t,
      PpForgeChip(label: 'ปรับยอด', size: ChipSize.chip, onTap: () => taps++),
    );
    final box = t.getRect(find.byType(PpForgeChip));
    // 28 high: 6 above / below still count; 12 above does not.
    await t.tapAt(box.topCenter - const Offset(0, 6));
    expect(taps, 1);
    await t.tapAt(box.topCenter - const Offset(0, 12));
    expect(taps, 1);
    // The layout is untouched.
    expect(box.height, ChipSize.chip.height);
  });

  testWidgets('a display chip has no extended target', (t) async {
    await pump(t, const PpForgeChip(label: 'ใช้งาน', size: ChipSize.mini));
    expect(find.byType(InkWell), findsOneWidget);
    expect(t.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('maxWidth caps the chip; the label ellipsises', (t) async {
    await pump(
      t,
      const PpForgeChip(
        label: 'ชื่อกระเป๋าที่ยาวมากๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆๆ',
        maxWidth: 120,
      ),
    );
    expect(t.getSize(find.byType(PpForgeChip)).width, lessThanOrEqualTo(120));
    expect(t.takeException(), isNull);
  });

  testWidgets('dashed draws a dashed outline, same height', (t) async {
    await pump(t, const PpForgeChip(label: 'เลือกกระเป๋า', dashed: true));
    expect(t.getSize(find.byType(PpForgeChip)).height, ChipSize.control.height);
    expect(find.byType(DashedRectBorder), findsOneWidget);
  });

  test('Tone maps onto PpForgeChipTone', () {
    expect(PpForgeChipTone.fromTone(Tone.warning), PpForgeChipTone.warning);
    expect(PpForgeChipTone.fromTone(Tone.neutral), PpForgeChipTone.neutral);
    expect(PpForgeChipTone.fromTone(Tone.danger), PpForgeChipTone.danger);
  });
}
