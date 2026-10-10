import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import 'add_tile.dart';
import 'locked_in_edit.dart';

/// Detail-page building blocks (category-detail style): frameless sections
/// of rows. Label left, value/control right — or label on top for long
/// values. Owner rules 2026-10-10 (#16 / #17): a hairline **between** rows,
/// and a tinted band ([SectionBand]) **between** sections.
///
/// ```dart
/// SectionCard(first: true, children: [
///   DetailRow(label: 'อีเมล', trailing: Text(email)),
///   DetailStacked(label: 'บันทึก', child: InlineField(...)),
/// ]),
/// SectionCard(title: 'การจัดการ', locked: editing, children: [...]),
/// ```

/// One section of a detail page: a [SectionBand] above it (unless [first]),
/// an optional [title] row, then [children] with a [RowDivider] between
/// each — pages don't place dividers themselves.
///
/// Sits in a list padded [AppSpacing.lg] at the sides (the detail-page
/// norm); the band reaches past that to the screen edges.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.children,
    this.title,
    this.trailing,
    this.first = false,
    this.locked = false,
    this.dividers = true,
    super.key,
  });

  final List<Widget> children;
  final String? title;

  /// A small action at the end of the title row (👁, share, …).
  final Widget? trailing;

  /// The page's first section — no band above it.
  final bool first;

  /// An action section in edit mode: dimmed and inert ([LockedInEdit]).
  /// The band stays as it is.
  final bool locked;

  /// false = no hairlines (one block that isn't a list of rows).
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasTitleRow = title != null || trailing != null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTitleRow)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              trailing == null ? AppSpacing.lg : AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? '',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        for (final (i, row) in children.indexed) ...[
          if (i > 0 && dividers) const RowDivider(),
          row,
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) const SectionBand(),
        LockedInEdit(locked: locked, child: body),
      ],
    );
  }
}

/// The separator between detail sections (#17): a tinted band, edge to
/// edge. [SectionCard] puts one above itself; use it directly only where a
/// page has a section that isn't a [SectionCard].
///
/// It breaks out of the page's side inset ([bleed] on each side) so pages
/// keep their usual padded list.
class SectionBand extends StatelessWidget {
  const SectionBand({this.bleed = AppSpacing.lg, super.key});

  /// How far past its box the band reaches on each side — the page's side
  /// padding.
  final double bleed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SizedBox(
        height: AppSpacing.sm,
        child: LayoutBuilder(
          builder: (context, box) => OverflowBox(
            minWidth: box.maxWidth + bleed * 2,
            maxWidth: box.maxWidth + bleed * 2,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "add one more" row at the end of a [SectionCard] (a number, a
/// split, …): a row-style [AddTile], inset like the rows around it.
class DetailAddRow extends StatelessWidget {
  const DetailAddRow({
    required this.label,
    required this.onTap,
    this.icon = AppIcons.add,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: AddTile(
        label: label,
        icon: icon,
        variant: AddTileVariant.row,
        onTap: onTap,
      ),
    );
  }
}

/// A row: label (+ optional helper) on the left, value/control on the right.
/// [onTap] makes the whole row tappable (pickers); [leading] adds an icon;
/// [onLongPress] = the view-mode "long-press to edit" on a row.
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    this.trailing,
    this.helper,
    this.leading,
    this.onTap,
    this.onLongPress,
    this.showChevron = false,
    super.key,
  });

  /// View mode: enter edit on this row (long-press).
  final VoidCallback? onLongPress;

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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
    if (onTap == null && onLongPress == null) return row;
    return InkWell(onTap: onTap, onLongPress: onLongPress, child: row);
  }
}

/// A row for long values: label on top, value full-width below. The
/// value's text starts where the label does (owner 2026-10-11): an
/// [InlineField] in here lets its padding hang out to the left
/// ([DetailStackedValue]), so view-mode text isn't indented under the label.
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
          DetailStackedValue(child: child),
        ],
      ),
    );
  }
}

/// Marks a [DetailStacked]'s value area: fields that pad their text
/// inside a box (an [InlineField]) shift left by that padding here, so the
/// text lines up with the label above.
class DetailStackedValue extends InheritedWidget {
  const DetailStackedValue({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DetailStackedValue>() != null;

  @override
  bool updateShouldNotify(DetailStackedValue old) => false;
}

/// Hairline divider between detail rows — [SectionCard] places them; use
/// it directly only in a plain list of rows.
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
