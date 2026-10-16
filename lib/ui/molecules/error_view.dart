import 'package:flutter/material.dart';

import '../atoms/ui_config.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';

/// Shown when an async call fails (design-sheet §8.5): an icon, a headline, a
/// sentence and — with [onRetry] — a retry button. The words come from the
/// app's [PpForgeErrors] (network / server / unexpected), so this piece knows
/// nothing about the app's exception type.
///
/// ```dart
/// ErrorView(error: state.error!, onRetry: () => cubit.load())
/// ```
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  /// Short headline for [e] — the same text the full view shows, for
  /// snackbars (a failed refresh while data is already on screen).
  static String titleFor(BuildContext context, Object e) =>
      PpForgeConfig.of(context).errors.describe(e).title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final config = PpForgeConfig.of(context);
    final info = config.errors.describe(error);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(PpForgeSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(info.icon, size: 64, color: scheme.error),
              const SizedBox(height: PpForgeSpacing.lg),
              Text(
                info.title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PpForgeSpacing.lg),
              Text(
                info.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: PpForgeSpacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(PpForgeIcons.refresh),
                  label: Text(config.strings.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
