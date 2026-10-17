import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_icon.dart';
import '../atoms/ui_config.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

class LoadMoreErrorRow extends StatelessWidget {
  const LoadMoreErrorRow({required this.onRetry, this.message, super.key});

  final VoidCallback? onRetry;

  final String? message;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final strings = UiConfig.stringsOf(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          AppIcon(
            AppIcons.error,
            size: AppIconSize.md,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message ?? strings.loadMoreFailed,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (onRetry != null)
            AppButton(
              label: strings.retry,
              variant: AppButtonVariant.text,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}
