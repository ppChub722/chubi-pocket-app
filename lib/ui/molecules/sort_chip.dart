import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../organisms/option_sheet.dart';
import '../tokens/app/app_icons.dart';
import 'option_menu.dart';

class SortOption<T> {
  const SortOption(this.value, this.label);

  final T value;
  final String label;
}

class SortChip<T> extends StatelessWidget {
  const SortChip({
    required this.value,
    required this.options,
    required this.onChanged,
    this.tooltip,
    this.icon,
    super.key,
  }) : assert(options.length > 0, 'SortChip needs at least one option');

  final T value;
  final List<SortOption<T>> options;
  final ValueChanged<T> onChanged;

  final String? tooltip;

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
      builder: (context, toggle) => AppChip(
        label: current.label,
        icon: icon ?? AppIcons.sort,
        trailing: AppChipTrailing.dropdown,
        tooltip: tooltip,
        onTap: toggle,
      ),
    );
  }
}
