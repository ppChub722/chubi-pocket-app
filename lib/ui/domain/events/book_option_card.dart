import 'package:flutter/material.dart';

import '../../atoms/app_icon.dart';
import '../../atoms/select_check.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../atoms/busy_scope.dart';

/// One book my part of an event bill can go to ("หนี้" / "รายการ"): a
/// bordered card with a tick, its icon, words and amount; [child] (the
/// person, the result box, the pickers) opens under it while ticked.
class BookOptionCard extends StatelessWidget {
  const BookOptionCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.checked,
    required this.onChanged,
    this.subtitle,
    this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget amount;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final child = this.child;
    return Material(
      color: checked ? scheme.primary.withValues(alpha: 0.06) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: checked ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BusyLock(
            child: InkWell(
              onTap: () => onChanged(!checked),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    SelectCheck(
                      value: checked,
                      onTap: () => onChanged(!checked),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppIcon(icon, color: scheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DefaultTextStyle.merge(
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      child: amount,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (checked && child != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}
