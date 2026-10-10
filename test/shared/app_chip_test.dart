import 'package:chubi_pocket/core/constants/app_icons.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
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
  List<Widget> variants(PillSize size, {VoidCallback? onRemove}) => [
    AppChip(label: 'ทั้งหมด', size: size),
    AppChip(label: 'ทั้งหมด', size: size, selected: true),
    AppChip(label: 'อาหาร', icon: AppIcons.category, size: size),
    AppChip(label: 'ใช้งาน', dot: true, selected: true, size: size),
    AppChip(
      label: 'สถานะ',
      trailing: AppChipTrailing.dropdown,
      size: size,
      onTap: () {},
    ),
    AppChip(
      label: 'กระเป๋า',
      trailing: AppChipTrailing.remove,
      onRemove: onRemove ?? () {},
      size: size,
    ),
    AppChip(
      label: 'โอนเงิน',
      icon: AppIcons.transfer,
      trailing: AppChipTrailing.lock,
      size: size,
    ),
    AppChip(
      label: 'สี',
      trailing: AppChipTrailing.count,
      count: 12,
      size: size,
    ),
    AppChip(
      label: 'ลี',
      leading: const UserAvatar(displayName: 'ลี'),
      size: size,
    ),
    AppChip(label: 'รายจ่าย', icon: AppIcons.expense, size: size),
    AppChip(label: 'ปิด', enabled: false, size: size),
  ];

  for (final size in PillSize.values) {
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
          AppChip(label: 'on', tone: AppChipTone.expense, selected: true),
          AppChip(label: 'off', tone: AppChipTone.expense),
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
      AppChip(
        label: 'กระเป๋า',
        trailing: AppChipTrailing.remove,
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
      AppChip(
        label: 'กระเป๋า',
        trailing: AppChipTrailing.remove,
        onTap: () => tapped++,
        onRemove: () => removed++,
      ),
    );
    await t.tap(find.byIcon(AppIcons.close));
    await t.tap(find.text('กระเป๋า'));
    expect((tapped, removed), (1, 1));
  });

  testWidgets('disabled ignores taps', (t) async {
    var tapped = 0;
    await pump(t, AppChip(label: 'ปิด', enabled: false, onTap: () => tapped++));
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
          AppChip(label: 'สี', trailing: AppChipTrailing.count, count: 7),
          AppChip(label: 'ประเภท', trailing: AppChipTrailing.lock),
        ],
      ),
    );
    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(AppIcons.lock), findsOneWidget);
  });
}
