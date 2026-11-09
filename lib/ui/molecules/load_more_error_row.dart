import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../tokens/button_icon_kind.dart';
import '../atoms/app_icon.dart';
import '../atoms/ui_config.dart';
import '../tokens/pp_forge_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

class LoadMoreErrorRow extends StatelessWidget {
  const LoadMoreErrorRow({required this.onRetry, this.message, super.key});

  final VoidCallback? onRetry;

  final String? message;

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
              kind: ButtonIconKind.retry,
              variant: PpForgeButtonVariant.text,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}
