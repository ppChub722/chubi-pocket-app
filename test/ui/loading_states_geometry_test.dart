import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_geometry_harness.dart';

typedef Piece = Widget Function(bool loading);

/// The loading rule (owner 2026-10-28): a control that spins (`loading`) or
/// fades (a locked [BusyScope]) keeps its exact size and position. Each piece
/// is pumped three times at the same spot — normal, loading, faded — and its
/// rect, and the rect of a marker right after it, must not move. Inputs have
/// no loading state: normal vs faded only.
void main() {
  const pieceKey = Key('piece');
  const afterKey = Key('after');
  void noop() {}

  final small = <String, Piece>{
    for (final v in AppButtonVariant.values)
      'AppButton.${v.name}': (l) =>
          AppButton(label: 'Save', variant: v, loading: l, onPressed: noop),
    for (final s in AppButtonSize.values)
      'AppButton size ${s.name} + icon': (l) => AppButton(
        label: 'Add',
        icon: AppIcons.add,
        trailingIcon: AppIcons.dropdown,
        size: s,
        loading: l,
        onPressed: noop,
      ),
    'AppButton disabled': (l) =>
        AppButton(label: 'Save', loading: l, onPressed: null),
    'AppIconButton': (l) =>
        AppIconButton(icon: AppIcons.share, loading: l, onPressed: noop),
    'AppIconButton badge': (l) => AppIconButton(
      icon: AppIcons.share,
      badgeCount: 3,
      loading: l,
      onPressed: noop,
    ),
    'AppIconButton.edit': (l) =>
        AppIconButton.edit(loading: l, onPressed: noop),
    'AppIconButton.bare': (l) =>
        AppIconButton.bare(icon: AppIcons.refresh, loading: l, onPressed: noop),
    'AppIconButton.filled': (l) =>
        AppIconButton.filled(icon: AppIcons.check, loading: l, onPressed: noop),
    'AppIconButton.flat': (l) =>
        AppIconButton.flat(icon: AppIcons.add, loading: l, onPressed: noop),
    'AppIconButton.close dense': (l) =>
        AppIconButton.close(dense: true, loading: l, onPressed: noop),
    'AppIconButton.more': (l) =>
        AppIconButton.more(loading: l, onPressed: noop),
    'AppIconButton.fab': (l) =>
        AppIconButton.fab(icon: AppIcons.add, loading: l, onPressed: noop),
    'CheckCircleButton': (l) =>
        CheckCircleButton(checked: true, loading: l, onChanged: (_) {}),
    for (final s in ChipSize.values)
      'AppChip ${s.name}': (l) => AppChip(
        label: 'Pay now',
        icon: AppIcons.check,
        size: s,
        loading: l,
        onTap: noop,
      ),
    'AppChip toggle selected': (l) =>
        AppChip(label: 'Monthly', selected: true, loading: l, onTap: noop),
    'AppChip dropdown': (l) => AppChip(
      label: 'Food',
      trailing: AppChipTrailing.dropdown,
      loading: l,
      onTap: noop,
    ),
    'AppChip remove': (l) => AppChip(
      label: 'Food',
      trailing: AppChipTrailing.remove,
      onRemove: noop,
      loading: l,
      onTap: noop,
    ),
    'AppSwitch on': (l) =>
        AppSwitch(value: true, loading: l, onChanged: (_) {}),
    'AppSwitch off': (l) =>
        AppSwitch(value: false, loading: l, onChanged: (_) {}),
  };

  const options = [
    SheetOption(value: 1, label: 'Monday'),
    SheetOption(value: 7, label: 'Sunday'),
  ];
  final rows = <String, Piece>{
    'SettingToggleRow': (l) => SettingToggleRow(
      label: 'Include in reports',
      caption: 'Counts in totals',
      value: true,
      loading: l,
      submits: false,
      onChanged: (_) {},
    ),
    'SettingDropdownRow': (l) => SettingDropdownRow<int>(
      label: 'Week starts on',
      value: 'Monday',
      options: options,
      selected: 1,
      loading: l,
      submits: false,
      onSelected: (_) {},
    ),
    'SettingMenuRow': (l) => SettingMenuRow<int>(
      label: 'Week starts on',
      value: 'Monday',
      options: options,
      selected: 1,
      loading: l,
      submits: false,
      onSelected: (_) {},
    ),
    'SettingPickRow': (l) => SettingPickRow(
      label: 'Main wallet',
      value: const Text('Cash'),
      loading: l,
      submits: false,
      onTap: noop,
    ),
    'AppDetailRow chevron': (l) => AppDetailRow(
      label: 'Category',
      icon: AppIcons.category,
      trailing: const Text('Food'),
      showChevron: true,
      loading: l,
      onTap: noop,
    ),
    'AppDetailRow value': (l) => AppDetailRow(
      label: 'Category',
      trailing: const Text('Food'),
      loading: l,
      onTap: noop,
    ),
    'AppDetailRow lock': (l) => AppDetailRow(
      label: 'Currency',
      trailing: const Text('THB'),
      locked: true,
      loading: l,
      onTap: noop,
    ),
    'AppDetailRow leading only': (l) => AppDetailRow(
      label: 'Open',
      icon: AppIcons.wallet,
      loading: l,
      onTap: noop,
    ),
    'AppListRow tap + trailing + action': (l) => AppListRow(
      leading: const Icon(AppIcons.wallet),
      title: 'Groceries',
      line2: const ListRowLine(parts: ['Today']),
      trailing: const ListRowTrailing.text('฿120'),
      actions: [ListRowAction.icon(AppIcons.close, loading: l, onTap: noop)],
      loading: l,
      onTap: noop,
    ),
    'AppListRow button action': (l) => AppListRow(
      leading: const Icon(AppIcons.wallet),
      title: 'Groceries',
      actions: [ListRowAction.button(AppIcons.check, loading: l, onTap: noop)],
      onTap: noop,
    ),
    'DangerRow': (l) => DangerRow(
      icon: AppIcons.delete,
      label: 'Delete',
      consequence: 'Gone for good',
      loading: l,
      onTap: noop,
    ),
  };

  final inputs = <String, Widget Function()>{
    'AppInput': () => AppInput(
      label: 'Description',
      controller: TextEditingController(text: 'Lunch'),
    ),
    'AppInput.card': () => AppInput.card(
      label: 'Description',
      controller: TextEditingController(text: 'Lunch'),
    ),
    'AppInput.inline editing': () => AppInput.inline(
      editing: true,
      controller: TextEditingController(text: 'Lunch'),
    ),
    'AppInput.search': () => AppInput.search(
      controller: TextEditingController(text: 'tea'),
      onChanged: (_) {},
    ),
    'AmountInput': () => AmountInput(
      controller: TextEditingController(text: '1,250'),
      currencySymbol: '฿',
      quickFills: const [AmountQuickFill(label: 'All', amount: 1250)],
    ),
    'DetailTextField': () => DetailTextField(
      label: 'Note',
      controller: TextEditingController(text: 'Split'),
      editing: true,
    ),
    'DatePickChip': () =>
        DatePickChip(date: DateTime(2026, 10, 28), onPick: noop),
    'SegmentedChoice': () => SegmentedChoice<int>(
      segments: const [ChoiceSegment(1, 'Expense'), ChoiceSegment(2, 'In')],
      selected: 1,
      onChanged: (_) {},
    ),
    'StepperPill': () =>
        StepperPill(label: 'Oct 2026', onPrev: noop, onNext: noop),
    'SelectCheck': () => SelectCheck(value: true, onTap: noop),
  };

  Future<(Rect, Rect)> measure(WidgetTester t, Widget piece, double w) async {
    t.view.physicalSize = Size(w, 900);
    t.view.devicePixelRatio = 1;
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: geometryTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      const SizedBox(width: 7),
                      Flexible(
                        child: KeyedSubtree(key: pieceKey, child: piece),
                      ),
                      const SizedBox(key: afterKey, width: 4, height: 4),
                    ],
                  ),
                  const SizedBox(key: Key('below'), width: 4, height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    final after = t.getRect(find.byKey(afterKey));
    final below = t.getRect(find.byKey(const Key('below')));
    return (t.getRect(find.byKey(pieceKey)), after.expandToInclude(below));
  }

  void same(String name, (Rect, Rect) a, (Rect, Rect) b, String state) {
    expect(b.$1, a.$1, reason: '$name: $state moved / resized the piece');
    expect(b.$2, a.$2, reason: '$name: $state moved what follows it');
  }

  for (final width in [320.0, 420.0]) {
    for (final MapEntry(key: name, value: build) in {
      ...small,
      ...rows,
    }.entries) {
      testWidgets('$name @$width: normal = loading = faded', (t) async {
        addTearDown(t.view.reset);
        final normal = await measure(t, build(false), width);
        final loading = await measure(t, build(true), width);
        expect(
          find.byType(AppSpinner),
          findsWidgets,
          reason: '$name: loading shows the spinner',
        );
        final faded = await measure(
          t,
          BusyScope(busy: true, child: build(false)),
          width,
        );
        same(name, normal, loading, 'loading');
        same(name, normal, faded, 'fading');
      });
    }
    for (final MapEntry(key: name, value: build) in inputs.entries) {
      testWidgets('$name @$width: normal = faded', (t) async {
        addTearDown(t.view.reset);
        final normal = await measure(t, build(), width);
        final faded = await measure(
          t,
          BusyScope(busy: true, child: build()),
          width,
        );
        same(name, normal, faded, 'fading');
        expect(find.byType(AppSpinner), findsNothing, reason: name);
      });
    }
  }
}
