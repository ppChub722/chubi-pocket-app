import 'package:flutter/material.dart';

import '../../tokens/app/app_colors.dart';
import '../../tokens/pp_forge_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import '../../atoms/busy_scope.dart';

/// An amber line in a hero (over budget, behind pace); tappable with [onTap].
class HeroAlert extends StatelessWidget {
  const HeroAlert({
    required this.text,
    this.onTap,
    this.icon = PpForgeIcons.warning,
    super.key,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final warning =
        HeroColors.maybeOf(context)?.warning ??
        Theme.of(context).extension<AppColors>()!.warning;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: warning,
      fontWeight: FontWeight.w600,
    );
    return Material(
      color: warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BusyLock(
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
                Icon(icon, size: 16, color: warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(text, style: style)),
                if (onTap != null)
                  Icon(PpForgeIcons.chevronRight, size: 16, color: warning),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
