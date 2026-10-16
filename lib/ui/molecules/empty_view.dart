import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

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
  }) : compact = false;

  /// A small empty line (no icon, no title): a muted caption centred in its
  /// space — an empty section inside a page.
  const EmptyView.compact({super.key, required this.message})
    : icon = Icons.inbox_outlined,
      title = '',
      cta = null,
      compact = true;

  final bool compact;
  final IconData icon;
  final String title;
  final String message;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PpForgeSpacing.lg,
          vertical: PpForgeSpacing.lg,
        ),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(PpForgeSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: scheme.onSurfaceVariant),
              const SizedBox(height: PpForgeSpacing.lg),
              Text(
                title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PpForgeSpacing.lg),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (cta != null) ...[
                const SizedBox(height: PpForgeSpacing.lg),
                cta!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
