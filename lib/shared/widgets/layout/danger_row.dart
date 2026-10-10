import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

/// Red full-width row at the bottom of a page for the destructive action —
/// "ลบหมวดหมู่นี้", "เก็บกระเป๋านี้ถาวร". Since the top bar carries no page
/// actions (owner rule 2026-10-09), delete / archive live here: shown only
/// in edit mode on pages that have one (a page with no in-place edit, e.g.
/// transaction detail, shows it always). The caller still confirms via
/// `showConfirmDialog` in [onTap].
///
/// [caution] = the amber one, same shape — เก็บถาวร (restorable) next to
/// the red ลบ (owner 2026-10-11, the การจัดการ block).
class DangerRow extends StatelessWidget {
  const DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.padding = const EdgeInsets.only(top: AppSpacing.xl),
    this.caution = false,
    super.key,
  });

  /// Amber (warning) instead of red: an undoable action (archive).
  final bool caution;

  final IconData icon;
  final String label;

  /// Null = disabled (e.g. while saving).
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = caution
        ? Theme.of(context).extension<AppColors>()!.warning
        : scheme.error;
    final color = onTap == null ? scheme.onSurfaceVariant : tint;
    return Padding(
      padding: padding,
      child: Material(
        color: tint.withValues(alpha: onTap == null ? 0.04 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
