import 'package:flutter/material.dart';

import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// "ต้องจัดการ": the occurrences that are due (or still need an amount), in
/// one card edged in the warning colour. [children] are [DueGroupHeader]s,
/// OccurrenceRows and [DueMoreRow]s, in that order per item.
class DueCard extends StatelessWidget {
  const DueCard({
    required this.title,
    required this.children,
    this.trailing,
    super.key,
  });

  final String title;

  /// Muted, at the header's end ("3 งวด").
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final warning = Theme.of(context).extension<AppColors>()!.warning;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: warning.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

/// One item's head inside a [DueCard] when it has several due occurrences:
/// "Netflix ค้าง 24 งวด", "ค้างตั้งแต่ พ.ย. 2024", and the all-at-once
/// actions (an OccurrenceActions: ยืนยันทั้งหมด, then จ่ายแล้ว / ข้ามทั้งหมด).
class DueGroupHeader extends StatelessWidget {
  const DueGroupHeader({
    required this.label,
    this.caption,
    this.actions,
    super.key,
  });

  final String label;
  final String? caption;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.sm),
            actions!,
          ],
        ],
      ),
    );
  }
}

/// "ดูทั้ง 24 งวด" (the chevron is added): the rest of an item's due
/// occurrences.
class DueMoreRow extends StatelessWidget {
  const DueMoreRow({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(AppIcons.chevronRight, size: 16, color: accent),
          ],
        ),
      ),
    );
  }
}
