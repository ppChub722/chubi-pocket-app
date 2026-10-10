import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// Rounded-square multi-select check (owner 2026-10-10: checkboxes are
/// square, not round) — the app's selection mark in edit mode (grid
/// cells, rows) and for "select all" above them, so both look the same.
///
/// [value]: `true` ✓ · `false` empty · `null` partial (−, select-all only).
class SelectCheck extends StatelessWidget {
  const SelectCheck({
    required this.value,
    required this.onTap,
    this.size = 20,
    this.tooltip,
    super.key,
  });

  final bool? value;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = value != false;
    final check = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        color: filled ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: filled ? scheme.primary : scheme.outline,
          width: 1.5,
        ),
      ),
      child: filled
          ? Icon(
              value == null ? Icons.remove : AppIcons.check,
              size: size * 0.7,
              color: scheme.onPrimary,
            )
          : null,
    );
    final tappable = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(padding: const EdgeInsets.all(4), child: check),
    );
    return tooltip == null
        ? tappable
        : Tooltip(message: tooltip!, child: tappable);
  }
}

/// "[☐ 2/5]" — select / deselect everything shown, with how many are
/// picked out of how many. No "เลือกทั้งหมด" label (owner 2026-10-10: the
/// box + count says it); the same control on every multi-select list.
class SelectAllCount extends StatelessWidget {
  const SelectAllCount({
    required this.selected,
    required this.total,
    required this.onTap,
    this.tooltip,
    super.key,
  });

  final int selected;
  final int total;

  /// Null (or nothing to pick) disables it.
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tap = total == 0 ? null : onTap;
    final value = selected == 0 ? false : (selected >= total ? true : null);
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectCheck(value: value, tooltip: tooltip, onTap: tap),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$selected/$total',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
