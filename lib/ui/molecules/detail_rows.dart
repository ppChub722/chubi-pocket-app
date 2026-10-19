import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/add_tile.dart';
import '../atoms/app_icon.dart';
import '../tokens/app_radius.dart';
import '../atoms/locked_in_edit.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.children,
    this.title,
    this.trailing,
    this.leading,
    this.onHeaderTap,
    this.description,
    this.first = false,
    this.locked = false,
    this.dividers = true,
    this.fields = false,
    super.key,
  });

  final List<Widget> children;
  final String? title;

  final String? description;

  final Widget? trailing;

  final Widget? leading;

  final VoidCallback? onHeaderTap;

  final bool first;

  final bool locked;

  final bool dividers;

  final bool fields;

  Widget _tappable(Widget header) => onHeaderTap == null
      ? header
      : InkWell(
          onTap: onHeaderTap,
          overlayColor: _restingOverlay,
          child: header,
        );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasTitleRow = title != null || trailing != null || leading != null;
    final reserve = children.any(
      (c) => c is DetailRow && (c.leading != null || c.icon != null),
    );
    const outer = Radius.circular(AppRadius.lg);
    // A rounded Material, NOT a ClipRRect: a framed field's notched label
    // overhangs its box by half a line, and a clip would cut it in half.
    Widget cell(int i, Widget row) {
      final radius = BorderRadius.vertical(
        top: i == 0 ? outer : Radius.zero,
        bottom: i == children.length - 1 ? outer : Radius.zero,
      );
      return ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.none,
        child: Material(
          color: scheme.surface,
          borderRadius: radius,
          child: fields
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    i == 0 ? AppSpacing.md : AppSpacing.xs,
                    AppSpacing.lg,
                    i == children.length - 1 ? AppSpacing.md : AppSpacing.xs,
                  ),
                  child: row,
                )
              : row,
        ),
      );
    }

    final group = DetailGroupScope(
      reserveIcon: reserve,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in children.indexed) ...[
            if (i > 0) SizedBox(height: dividers ? 2 : 0),
            cell(i, row),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) const SizedBox(height: AppSpacing.lg),
        if (hasTitleRow || description != null)
          _tappable(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasTitleRow)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.xs,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Text(
                            title ?? '',
                            style: text.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                  ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      description!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (children.isNotEmpty) LockedInEdit(locked: locked, child: group),
      ],
    );
  }
}

final WidgetStateProperty<Color?> _restingOverlay =
    WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.pressed) ? null : Colors.transparent,
    );

class DetailGroupScope extends InheritedWidget {
  const DetailGroupScope({
    required this.reserveIcon,
    required super.child,
    super.key,
  });

  final bool reserveIcon;

  static bool reserves(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DetailGroupScope>()
          ?.reserveIcon ??
      false;

  @override
  bool updateShouldNotify(DetailGroupScope old) =>
      reserveIcon != old.reserveIcon;
}

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

class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    this.trailing,
    this.helper,
    this.error,
    this.leading,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.showChevron = false,
    this.locked = false,
    this.horizontalInset = AppSpacing.lg,
    super.key,
  });

  factory DetailRow.pick({
    required String label,
    String? value,
    Widget? valueChip,
    List<Widget>? valueChips,
    required String emptyText,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    String? helper,
    String? error,
    Widget? leading,
    IconData? icon,
    bool locked = false,
    double horizontalInset = AppSpacing.lg,
    Key? key,
  }) => DetailRow(
    key: key,
    label: label,
    helper: helper,
    error: error,
    leading: leading,
    icon: icon,
    locked: locked,
    horizontalInset: horizontalInset,
    onTap: onTap,
    onLongPress: onLongPress,
    showChevron: onTap != null,
    trailing: _PickValue(
      value: value,
      chip: valueChip,
      chips: valueChips,
      emptyText: emptyText,
    ),
  );

  final VoidCallback? onLongPress;

  final String label;
  final Widget? trailing;
  final String? helper;

  final String? error;
  final Widget? leading;

  final IconData? icon;
  final VoidCallback? onTap;

  final bool showChevron;

  final bool locked;

  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null || icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
                child: leading ?? AppIcon(icon!),
              ),
              const SizedBox(width: AppSpacing.md),
            ] else if (DetailGroupScope.reserves(context)) ...[
              const SizedBox(width: 22 + AppSpacing.md),
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
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * 0.5),
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.right,
                  child: trailing!,
                ),
              ),
            ],
            if (locked) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.lock, size: 16, color: scheme.onSurfaceVariant),
            ],
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.chevronRight, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
    if (onTap == null && onLongPress == null) return row;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      overlayColor: _restingOverlay,
      child: row,
    );
  }
}

class DetailPlaceholder extends StatelessWidget {
  const DetailPlaceholder(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
    );
  }
}

class _PickValue extends StatelessWidget {
  const _PickValue({
    required this.value,
    required this.chip,
    required this.emptyText,
    this.chips,
  });

  final String? value;
  final Widget? chip;
  final List<Widget>? chips;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final many = chips;
    if (many != null && many.isNotEmpty) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: many,
      );
    }
    if (chip != null) return chip!;
    final empty = value == null || value!.isEmpty;
    if (empty) return DetailPlaceholder(emptyText);
    return Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class DetailStacked extends StatelessWidget {
  const DetailStacked({
    required this.label,
    required this.child,
    this.onLongPress,
    this.leading,
    super.key,
  });

  final String label;
  final Widget child;

  final VoidCallback? onLongPress;

  /// An icon left of the label and field; null = the [DetailLeadingScope]'s.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final lead = leading ?? DetailLeadingScope.of(context);
    final stack = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: detailLabelStyle(context)),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
    final block = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: lead == null
          ? stack
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTheme.merge(
                  data: IconThemeData(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  child: lead,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: stack),
              ],
            ),
    );
    if (onLongPress == null) return block;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: block,
    );
  }
}

TextStyle? detailLabelStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );

/// Gives the [DetailStacked] rows under it a leading icon, so a section can
/// show the same icon in edit mode as in view (the note's 📝) whatever field
/// a page passes it.
class DetailLeadingScope extends InheritedWidget {
  const DetailLeadingScope({
    required this.leading,
    required super.child,
    super.key,
  });

  final Widget leading;

  static Widget? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DetailLeadingScope>()?.leading;

  @override
  bool updateShouldNotify(DetailLeadingScope old) => leading != old.leading;
}
