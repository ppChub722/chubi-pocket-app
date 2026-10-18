import 'package:flutter/material.dart';

import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// An amber line in a hero (over budget, behind pace); tappable with [onTap].
class HeroAlert extends StatelessWidget {
  const HeroAlert({
    required this.text,
    this.onTap,
    this.icon = AppIcons.warning,
    super.key,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: palette.warning,
      fontWeight: FontWeight.w600,
    );
    return Material(
      color: palette.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: palette.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(text, style: style)),
              if (onTap != null)
                Icon(AppIcons.chevronRight, size: 16, color: palette.warning),
            ],
          ),
        ),
      ),
    );
  }
}
