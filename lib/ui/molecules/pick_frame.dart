import 'package:flutter/material.dart';

import '../atoms/app_icon_button.dart';
import '../atoms/dashed_rect_border.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';

/// Edit mode for a group that is picked as a whole (a budget's categories,
/// wallets, tags): the group sits in one dashed frame, and a tap anywhere in
/// it opens the picker. The chips inside have a normal line and no ✕.
class PickFrame extends StatelessWidget {
  const PickFrame({required this.onTap, required this.child, super.key});

  final VoidCallback onTap;

  /// The picked items, or a [PickFramePrompt] while nothing is picked.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DashedRectBorder(
      color: Theme.of(context).colorScheme.outline,
      strokeWidth: 1,
      dashLength: 4,
      gapLength: 3,
      borderRadius: const Radius.circular(AppRadius.md),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}

/// One picked item shown as its own list row (a linked transaction) in a
/// dashed frame: a tap picks again, ✕ takes it off.
class PickedRowFrame extends StatelessWidget {
  const PickedRowFrame({
    required this.child,
    this.onTap,
    this.onRemove,
    this.removeTooltip,
    super.key,
  });

  /// The row (it keeps its own padding).
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final String? removeTooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DashedRectBorder(
      color: scheme.primary,
      strokeWidth: 1.5,
      dashLength: 4,
      gapLength: 3,
      borderRadius: const Radius.circular(AppRadius.md),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Row(
            children: [
              Expanded(child: IgnorePointer(child: child)),
              if (onRemove != null)
                AppIconButton.flat(
                  icon: AppIcons.close,
                  tooltip: removeTooltip,
                  dense: true,
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What an empty [PickFrame] says: "+ choose …", one chip tall.
class PickFramePrompt extends StatelessWidget {
  const PickFramePrompt(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: ChipSize.chip.heightOf(context),
      child: Row(
        children: [
          Icon(AppIcons.add, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
