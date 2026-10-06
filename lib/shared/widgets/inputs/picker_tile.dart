import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// Form row that opens a picker: leading visual, small label over the
/// current value, optional trailing info, chevron. Used for account,
/// category, date, currency, contact … fields in every form.
///
/// [value] null → shows [placeholder] in the muted colour.
/// [readOnly] hides the chevron and disables taps.
class PickerTile extends StatelessWidget {
  const PickerTile({
    required this.label,
    required this.onTap,
    this.value,
    this.placeholder,
    this.leading,
    this.trailing,
    this.readOnly = false,
    this.errorText,
    super.key,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final Widget? leading;

  /// Extra info before the chevron (e.g. account balance).
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool readOnly;

  /// Validation message shown under the tile (border turns error colour).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasError = errorText != null;
    final tile = Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: hasError
            ? BorderSide(color: scheme.error)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: readOnly ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                if (leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                        color: scheme.onSurfaceVariant, size: 24),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        value ?? placeholder ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: value == null ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  DefaultTextStyle.merge(
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    child: trailing!,
                  ),
                ],
                if (!readOnly)
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
    if (!hasError) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
          child: Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ),
      ],
    );
  }
}
