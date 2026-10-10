import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../menus/option_menu.dart';
import '../sheets/option_sheet.dart';
import 'pill.dart';

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

  static const _size = PillSize.normal;

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
            color: isActive ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            // The one chip size (PillSize.normal), like every chip.
            constraints: BoxConstraints(minHeight: _size.height),
            child: Padding(
              padding: EdgeInsets.only(
                left: _size.padding,
                right: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: _size.icon, color: fg),
                    SizedBox(width: _size.gap),
                  ],
                  Text(
                    text,
                    style: _size
                        .textStyle(context)
                        ?.copyWith(
                          color: isActive ? scheme.primary : fg,
                          fontWeight: PillSize.chipWeight,
                        ),
                  ),
                  Icon(AppIcons.dropdown, size: 20, color: fg),
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
          constraints: BoxConstraints(minHeight: PillSize.normal.height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.sort, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  current.label,
                  style: PillSize.normal
                      .textStyle(context)
                      ?.copyWith(fontWeight: PillSize.chipWeight),
                ),
                Icon(AppIcons.dropdown, color: scheme.onSurfaceVariant),
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
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
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

/// How an [ActionPill] sits on its background.
enum ActionPillStyle {
  /// Tinted fill + tinted border — rows of actions (selection bars).
  tinted,

  /// Raised surface chip with a shadow — one action floating on a card
  /// (the wallet header's "ปรับยอด").
  raised,
}

/// Icon + label button — the action role of the pill family
/// ([PillSize.normal], the height of every chip), so it sits in any chip
/// row. Used by selection bars ("[◉ 3] [🎨 สี] [⬡
/// ไอคอน] [🗑 ลบ]") and header actions ("ปรับยอด").
class ActionPill extends StatelessWidget {
  const ActionPill({
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
    this.style = ActionPillStyle.tinted,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool destructive;
  static const size = PillSize.normal;
  final ActionPillStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = destructive ? scheme.error : scheme.primary;
    final raised = style == ActionPillStyle.raised;
    return Opacity(
      opacity: onTap != null ? 1 : 0.4,
      child: PillShell(
        size: size,
        background: raised
            ? scheme.surfaceContainerHigh
            : fg.withValues(alpha: 0.10),
        border: raised ? scheme.outlineVariant : fg.withValues(alpha: 0.5),
        elevation: raised ? 1.5 : 0,
        onTap: onTap,
        child: PillContent(
          label: label,
          color: fg,
          size: size,
          leading: icon == null ? null : Icon(icon, size: size.icon, color: fg),
        ),
      ),
    );
  }
}
