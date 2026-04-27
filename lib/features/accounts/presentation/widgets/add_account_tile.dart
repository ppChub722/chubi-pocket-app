import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/dashed_rect_border.dart';

/// Last tile in the accounts grid — visually distinct from real account
/// cards so the user can see at a glance "this is the way to add one,
/// everything above is mine."
///
/// Visual treatment (locked in design discussion):
/// - Dashed border in brand primary color
/// - Transparent background (no fill)
/// - Centered "+" icon and label, both stacked vertically and centered both
///   horizontally and vertically — different shape from real account cards
///   (which left-align icon and content)
class AddAccountTile extends StatelessWidget {
  const AddAccountTile({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return DashedRectBorder(
      color: scheme.primary,
      strokeWidth: 1.5,
      dashLength: 6,
      gapLength: 4,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 28, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l.accountsAddNew,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
