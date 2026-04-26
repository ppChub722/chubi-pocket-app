import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

/// Shown when an async call succeeds but returns zero rows.
///
/// Per design-sheet §8.5: centered, vertical stack — 64 dp icon, headline
/// title, body message, optional CTA.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.cta,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: scheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (cta != null) ...[
                const SizedBox(height: AppSpacing.lg),
                cta!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
