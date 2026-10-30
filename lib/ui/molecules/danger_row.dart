import 'package:flutter/material.dart';

import '../atoms/busy_scope.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app/app_colors.dart';

class DangerRow extends StatelessWidget {
  const DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.padding = const EdgeInsets.only(top: AppSpacing.xl),
    this.caution = false,
    this.neutral = false,
    this.consequence,
    this.loading = false,
    super.key,
  });

  final String? consequence;

  /// The primary colour, same shape: a harmless action that ends something
  /// without losing it (ปิดงบ) — not a warning.
  final bool neutral;

  /// Amber (warning) instead of red: an undoable action (archive).
  final bool caution;

  final IconData icon;
  final String label;

  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// The pressed action while its call runs: a spinner in place of the icon,
  /// same size, taps ignored (see [BusyScope]).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = neutral
        ? scheme.primary
        : caution
        ? Theme.of(context).extension<AppColors>()!.warning
        : scheme.error;
    final busy = BusyScope.control(
      context,
      loading: loading,
      enabled: onTap != null,
    );
    final enabled = onTap != null || busy.spinning;
    final color = enabled ? tint : scheme.onSurfaceVariant;
    return Padding(
      padding: padding,
      child: BusyLock(
        locked: busy.locked,
        inert: busy.spinning,
        child: Material(
          color: tint.withValues(alpha: enabled ? 0.08 : 0.04),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BusySwap(
                          loading: busy.spinning,
                          color: color,
                          spinnerSize: 18,
                          child: Icon(icon, size: 20, color: color),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (consequence != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          consequence!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
