import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_icon.dart';
import '../atoms/ui_config.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

/// The end of a paged list when the next page failed: "couldn't load more"
/// + Retry, in place of the loading rows. The rows already loaded stay above
/// it; `ListPageBody` shows it from its `loadMoreError`.
class LoadMoreErrorRow extends StatelessWidget {
  const LoadMoreErrorRow({required this.onRetry, this.message, super.key});

  /// Null = no retry button (nothing to call).
  final VoidCallback? onRetry;

  /// Defaults to [PpForgeStrings.loadMoreFailed].
  final String? message;

  /// The same height as a list row, so nothing jumps when it swaps with the
  /// loading rows.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final strings = PpForgeConfig.stringsOf(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          PpForgeIcon(
            PpForgeIcons.error,
            size: PpForgeIconSize.md,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: PpForgeSpacing.sm),
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
            PpForgeButton(
              label: strings.retry,
              variant: PpForgeButtonVariant.text,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}
