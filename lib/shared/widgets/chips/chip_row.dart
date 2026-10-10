import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';

/// A chip row's order, fixed once the lists it ranks have loaded (option B,
/// owner 2026-10-10): tapping a chip highlights it in place — nothing jumps
/// to the front. One picked elsewhere ("เพิ่มเติม") that isn't in the row
/// joins at the end, and stays. Keep one per row for the screen's life
/// (in a State).
class ChipOrder {
  List<String>? _frozen;

  /// [rank] is the order as of now — kept from the first call where
  /// [ready] (until then it's re-ranked every build, so a cold cache
  /// doesn't freeze an empty row). [picked] ids missing from it are added
  /// at the end.
  List<String> ids({
    required bool ready,
    required List<String> Function() rank,
    required Iterable<String> picked,
  }) {
    final out = _frozen ?? rank();
    if (ready) _frozen ??= out;
    for (final id in picked) {
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }
}

/// `[icon]  [chip] [chip] … [⋯ เพิ่มเติม]` — one pick row of a form or a
/// filter: a muted leading [icon] says what the row is (no label), the
/// chips scroll sideways, and [onMore] adds "เพิ่มเติม" at the end (the
/// full picker). The transaction form's หมวด / แท็ก rows, the filter
/// sheet's ประเภท / กระเป๋า / หมวด / แท็ก rows. Under a section title
/// that carries the icon (the filter sheet), [icon] is null and the chips
/// start flush left.
class ChipRow extends StatelessWidget {
  const ChipRow({
    required this.chips,
    this.icon,
    this.onMore,
    this.moreLabel,
    super.key,
  });

  /// Null = no leading icon (a titled section shows it instead).
  final IconData? icon;
  final List<Widget> chips;

  /// Null = no "เพิ่มเติม" (a view-only row).
  final VoidCallback? onMore;

  /// The "เพิ่มเติม" text — required with [onMore].
  final String? moreLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in chips) ...[
                  c,
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (onMore != null)
                  RowChip(
                    label: moreLabel ?? '',
                    icon: AppIcons.more,
                    onTap: onMore,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A chip of a [ChipRow] — `[icon] label`, the same size and look as the
/// category / tag chips beside it: [selected] = tinted in [color] with a
/// [color] border, otherwise a neutral outline (the icon keeps [color]).
/// [color] null = the theme's primary; the "ทั้งหมด" / "เพิ่มเติม" chips
/// leave it.
class RowChip extends StatelessWidget {
  const RowChip({
    required this.label,
    this.icon,
    this.color,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    final fg = selected ? tint : scheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: Material(
        color: selected ? tint.withValues(alpha: 0.12) : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? tint : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: color == null ? fg : tint),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
