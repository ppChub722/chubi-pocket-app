import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../organisms/option_sheet.dart';
import '../tokens/app/app_icons.dart';
import 'option_menu.dart';

/// One choice of a [SortChip]: the value and the label shown in the chip and
/// in the popover.
class SortOption<T> {
  const SortOption(this.value, this.label);

  final T value;
  final String label;
}

/// A list's sort control (owner 2026-10-12): a chip with the sort icon, the
/// current option's label and ▾. Tapping it opens the central popover
/// ([OptionMenuAnchor]) with every option; the current one is highlighted
/// (never a ✓). Picking one calls [onChanged].
///
///   [⇅ Newest ▾]
///
/// No size of its own: inside a `ListToolbar` it follows the toolbar's
/// [ChipSizeScope] (chip 28, one size below the search capsule); elsewhere
/// it is a control chip (40). Put it in the toolbar's `trailing` slot.
class SortChip<T> extends StatelessWidget {
  const SortChip({
    required this.value,
    required this.options,
    required this.onChanged,
    this.tooltip,
    this.icon,
    super.key,
  }) : assert(options.length > 0, 'SortChip needs at least one option');

  /// The current sort.
  final T value;
  final List<SortOption<T>> options;
  final ValueChanged<T> onChanged;

  /// A tap-to-read hint on the chip.
  final String? tooltip;

  /// The chip's leading icon — null = the sort icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );
    return OptionMenuAnchor<T>(
      selected: value,
      onSelected: onChanged,
      options: [
        for (final o in options) SheetOption<T>(value: o.value, label: o.label),
      ],
      builder: (context, toggle) => PpForgeChip(
        label: current.label,
        icon: icon ?? PpForgeIcons.sort,
        trailing: PpForgeChipTrailing.dropdown,
        tooltip: tooltip,
        onTap: toggle,
      ),
    );
  }
}
