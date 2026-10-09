import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import 'app_sheet.dart';

/// One row of [showActionSheet].
class SheetAction<T> {
  const SheetAction({
    required this.value,
    required this.label,
    required this.icon,
    this.subtitle,
    this.destructive = false,
    this.enabled = true,
  });

  final T value;
  final String label;
  final IconData icon;

  /// Why it's disabled, or what it does.
  final String? subtitle;

  /// Red — delete, remove, leave.
  final bool destructive;
  final bool enabled;
}

/// The app's "what do you want to do with this?" sheet: an optional
/// [header] (what was tapped — [ActionSheetHeader]) over a list of
/// [actions]. Resolves the picked action's value, or null on dismiss.
///
/// For picking one value of many use `showOptionSheet` instead.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  required List<SheetAction<T>> actions,
  Widget? header,
}) {
  return showAppSheet<T>(
    context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[
          header,
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),
        ],
        for (final a in actions) _ActionRow(action: a),
        const SizedBox(height: AppSpacing.md),
      ],
    ),
  );
}

/// The tapped thing at the top of an action sheet: leading (avatar /
/// icon) · title + subtitle · trailing (amount, pill).
class ActionSheetHeader extends StatelessWidget {
  const ActionSheetHeader({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ActionRow<T> extends StatelessWidget {
  const _ActionRow({required this.action});

  final SheetAction<T> action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final a = action;
    final color = a.destructive ? scheme.error : scheme.onSurface;
    return Opacity(
      opacity: a.enabled ? 1 : 0.4,
      child: InkWell(
        onTap: a.enabled ? () => Navigator.pop(context, a.value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                a.icon,
                size: 22,
                color: a.destructive ? scheme.error : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      a.label,
                      style: textTheme.bodyLarge?.copyWith(color: color),
                    ),
                    if (a.subtitle != null)
                      Text(
                        a.subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
