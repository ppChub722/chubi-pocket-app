import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';

/// Detail-page building blocks (category-detail style): a frameless group
/// of rows separated by hairlines. Label left, value/control right — or
/// label on top for long values.
///
/// ```dart
/// SectionCard(children: [
///   DetailRow(label: 'อีเมล', trailing: Text(email)),
///   const RowDivider(),
///   DetailStacked(label: 'บันทึก', child: InlineField(...)),
/// ])
/// ```

/// Groups detail rows. No outer frame — rows sit on the page, separated by
/// [RowDivider]s. Optional [title] renders a small section heading.
class SectionCard extends StatelessWidget {
  const SectionCard({required this.children, this.title, super.key});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ...children,
      ],
    );
  }
}

/// A row: label (+ optional helper) on the left, value/control on the right.
/// [onTap] makes the whole row tappable (pickers); [leading] adds an icon.
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    this.trailing,
    this.helper,
    this.leading,
    this.onTap,
    this.showChevron = false,
    super.key,
  });

  final String label;
  final Widget? trailing;
  final String? helper;
  final Widget? leading;
  final VoidCallback? onTap;

  /// Shows a `›` after [trailing] — use for rows that navigate / open a sheet.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            IconTheme.merge(
              data: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
              child: leading!,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: detailLabelStyle(context)),
                if (helper != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    helper!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.right,
                  child: trailing!,
                ),
              ),
            ),
          ],
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.chevronRight, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// A row for long values: label on top, value full-width below.
class DetailStacked extends StatelessWidget {
  const DetailStacked({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: detailLabelStyle(context)),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

/// Hairline divider between detail rows.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Bold label style shared by [DetailRow] / [DetailStacked].
TextStyle? detailLabelStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        );
