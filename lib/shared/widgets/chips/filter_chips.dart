import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../menus/option_menu.dart';
import '../sheets/option_sheet.dart';

/// Dropdown-style filter chip ("สี ▾", "สถานะ: ค้างอยู่ ▾", "กระเป๋า ▾").
///
/// Purely visual + [onTap] — wrap it in an `OptionMenuAnchor` /
/// `MultiOptionMenuAnchor` / `PopoverAnchor` (short lists) or open
/// `showOptionSheet` (long lists). Active when [count] > 0 or [valueLabel]
/// is set (or [active] forces it): primary-tinted fill + primary border and
/// text, and shows the count / value.
class FilterDropdownChip extends StatelessWidget {
  const FilterDropdownChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.count = 0,
    this.valueLabel,
    this.active,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Multi-select count → "สี (2)".
  final int count;

  /// Single-select value → "สถานะ: ค้างอยู่".
  final String? valueLabel;

  /// Overrides the computed active state.
  final bool? active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = active ?? (count > 0 || valueLabel != null);
    final enabled = onTap != null;
    final text = valueLabel != null
        ? '$label: $valueLabel'
        : (count > 0 ? '$label ($count)' : label);
    final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: isActive
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
              color: isActive ? scheme.primary : scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.md, right: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    text,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isActive ? scheme.primary : null,
                          fontWeight: isActive ? FontWeight.w600 : null,
                        ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 20, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One option of a [SortChip].
class SortOption<T> {
  const SortOption(this.value, this.label);
  final T value;
  final String label;
}

/// "⇅ ชื่อ ▾" sort selector — opens a popup menu of [options].
class SortChip<T> extends StatelessWidget {
  const SortChip({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<SortOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = options.firstWhere(
      (o) => o.value == selected,
      orElse: () => options.first,
    );
    return OptionMenuAnchor<T>(
      selected: selected,
      onSelected: onSelected,
      options: [
        for (final o in options) SheetOption(value: o.value, label: o.label),
      ],
      builder: (context, toggle) => InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(current.label,
                    style: Theme.of(context).textTheme.labelLarge),
                Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of filter chips (+ optional trailing sort chip) that
/// scrolls sideways when it overflows — the toolbar row under a search bar.
class FilterBar extends StatelessWidget {
  const FilterBar({required this.chips, this.trailing, super.key});

  final List<Widget> chips;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    chips[i],
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
