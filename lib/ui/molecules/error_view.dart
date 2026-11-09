import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../tokens/button_icon_kind.dart';
import '../atoms/ui_config.dart';
import '../tokens/pp_forge_icons.dart';
import '../tokens/app_spacing.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  static String titleFor(BuildContext context, Object e) =>
      UiConfig.of(context).errors.describe(e).title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final config = UiConfig.of(context);
    final info = config.errors.describe(error);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(info.icon, size: 64, color: scheme.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                info.title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                info.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: config.strings.retry,
                  kind: ButtonIconKind.retry,
                  onPressed: onRetry,
                  icon: PpForgeIcons.refresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
