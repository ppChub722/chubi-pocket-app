import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_chip.dart';
import '../../atoms/select_check.dart';
import '../../molecules/date_tile.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import 'occurrence_row.dart';

/// Under a recurring item's hero: the one occurrence to act on. [warning]
/// (something is due): edged and washed in the warning colour, with a
/// [title] head ("ต้องจัดการ", [trailing] count). Otherwise the next
/// occurrence, quiet. Either way: a calendar sheet, [label] over the big
/// [value], the [actions] as equal buttons (the first filled when
/// [primaryFirst]), then [footer] rows (DueGroupHeader, DueMoreRow,
/// [OccurrenceFocusNext]).
class OccurrenceFocusCard extends StatelessWidget {
  const OccurrenceFocusCard({
    required this.date,
    required this.label,
    required this.value,
    this.valueColor,
    this.tag,
    this.title,
    this.trailing,
    this.actions = const [],
    this.primaryFirst = false,
    this.footer = const [],
    this.warning = false,
    this.onTap,
    super.key,
  });

  final DateTime date;
  final String label;

  /// MoneyText, or a Text ("รอใส่ยอด") with [valueColor].
  final Widget value;
  final Color? valueColor;

  /// A state pill beside [label] ("รอยืนยัน").
  final Widget? tag;
  final String? title;
  final String? trailing;
  final List<OccurrenceAction> actions;
  final bool primaryFirst;
  final List<Widget> footer;
  final bool warning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final warn = theme.extension<AppColors>()!.warning;
    final muted = scheme.onSurfaceVariant;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: warning
            ? Color.alphaBlend(warn.withValues(alpha: 0.07), scheme.surface)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: warning ? warn.withValues(alpha: 0.6) : scheme.outlineVariant,
          width: warning ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Icon(AppIcons.warning, size: 18, color: warn),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      title!,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: warn,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CalendarTile(date: date, color: warning ? warn : null),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall?.copyWith(color: muted),
                              ),
                            ),
                            if (tag != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              tag!,
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        DefaultTextStyle.merge(
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: valueColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          child: value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  for (final (i, a) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _button(
                        context,
                        a,
                        primary: primaryFirst && i == 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ...footer,
          if (footer.isNotEmpty) const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }

  Widget _button(
    BuildContext context,
    OccurrenceAction a, {
    required bool primary,
  }) {
    final theme = Theme.of(context);
    Widget button = AppButton(
      label: a.label,
      onPressed: a.onTap,
      variant: a.destructive
          ? AppButtonVariant.destructive
          : primary
          ? AppButtonVariant.primary
          : AppButtonVariant.outlined,
      size: AppButtonSize.control,
      expand: true,
    );
    if (primary && a.warning && !a.destructive) {
      final warn = theme.extension<AppColors>()!.warning;
      button = Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: warn,
            onPrimary: AppChip.readableOn(warn, Colors.white),
          ),
        ),
        child: button,
      );
    }
    return button;
  }
}

/// The next occurrence as one line at the foot of an [OccurrenceFocusCard]
/// that shows a due one: "ครั้งถัดไป | อีก 27 วัน | 19 พ.ย." and its amount.
class OccurrenceFocusNext extends StatelessWidget {
  const OccurrenceFocusNext({
    required this.label,
    this.amount,
    this.onTap,
    super.key,
  });

  final String label;
  final Widget? amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + AppSpacing.xxs,
          ),
          child: Row(
            children: [
              Icon(AppIcons.date, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (amount != null)
                DefaultTextStyle.merge(
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  child: amount!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "ต้องจัดการ": the occurrences that are due (or still need an amount), in
/// one card edged and washed in the warning colour (as [OccurrenceFocusCard]).
/// [children]: a [DueSelectBar] first when rows can be picked, then
/// OccurrenceRows, [DueGroupHeader]s and [DueMoreRow]s. With [onToggle] it
/// folds like a hero card: ⌄ / ⌃ at the head's end (the whole head taps);
/// folded, the head line alone.
class DueCard extends StatelessWidget {
  const DueCard({
    required this.title,
    required this.children,
    this.trailing,
    this.open = true,
    this.onToggle,
    super.key,
  });

  final String title;

  /// Muted, at the header's end ("4").
  final String? trailing;
  final List<Widget> children;
  final bool open;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final warning = Theme.of(context).extension<AppColors>()!.warning;
    final shown = open || onToggle == null;
    final head = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        onToggle == null ? AppSpacing.lg : AppSpacing.md,
        shown ? AppSpacing.xs : AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(AppIcons.warning, size: 18, color: warning),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: warning,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          if (onToggle != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              shown ? AppIcons.collapse : AppIcons.expand,
              key: const ValueKey('dueCardFold'),
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          warning.withValues(alpha: 0.07),
          scheme.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: warning.withValues(alpha: 0.6), width: 1.5),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggle == null)
              head
            else
              Semantics(
                button: true,
                expanded: shown,
                child: InkWell(onTap: onToggle, child: head),
              ),
            if (shown) ...[...children, const SizedBox(height: AppSpacing.xs)],
          ],
        ),
      ),
    );
  }
}

/// The first row of a [DueCard] whose rows can be picked: a check for all
/// ([selectLabel]: "เลือกทั้งหมด" / "เลือกแล้ว 2"), then [skipLabel] and
/// [confirmLabel] for the picked ones, off until something is picked.
class DueSelectBar extends StatelessWidget {
  const DueSelectBar({
    required this.selected,
    required this.total,
    required this.onSelectAll,
    required this.selectLabel,
    required this.skipLabel,
    required this.confirmLabel,
    required this.onSkip,
    required this.onConfirm,
    this.heading = false,
    this.open = true,
    this.onToggle,
    super.key,
  });

  /// [selectLabel] is a section's name ("รอใส่ยอด 11"), set like a title.
  final bool heading;

  /// With [onToggle]: ⌄ / ⌃ at the end folds the section's rows (this bar
  /// stays).
  final bool open;
  final VoidCallback? onToggle;
  final int selected;
  final int total;
  final VoidCallback onSelectAll;
  final String selectLabel;
  final String skipLabel;
  final String confirmLabel;
  final VoidCallback onSkip;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final any = selected > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        // The same start as an AppListRow: its check sits over the rows'.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const ValueKey('dueSelectAll'),
                  onTap: onSelectAll,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Row(
                    children: [
                      SelectCheck(
                        value: selected == 0
                            ? false
                            : selected >= total
                            ? true
                            : null,
                        onTap: onSelectAll,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          selectLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: heading
                              ? Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)
                              : Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The buttons scale down on a narrow screen instead of
              // overflowing; the label keeps at least [_minLabel].
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (box.maxWidth - _minLabel).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        key: const ValueKey('dueSkipSelected'),
                        label: skipLabel,
                        onPressed: any ? onSkip : null,
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.chip,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        key: const ValueKey('dueConfirmSelected'),
                        label: confirmLabel,
                        onPressed: any ? onConfirm : null,
                        size: AppButtonSize.chip,
                      ),
                    ],
                  ),
                ),
              ),
              if (onToggle != null)
                Semantics(
                  button: true,
                  expanded: open,
                  child: InkResponse(
                    key: const ValueKey('dueSectionFold'),
                    onTap: onToggle,
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.xs,
                      ),
                      child: Icon(
                        open ? AppIcons.collapse : AppIcons.expand,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The room the select label always keeps (check + a few letters + the
  /// fold arrow).
  static const _minLabel = 120.0;
}

/// One item's head inside a [DueCard] when it has several due occurrences:
/// "Netflix ค้าง 24 งวด", "ค้างตั้งแต่ พ.ย. 2024", and the all-at-once
/// actions (an OccurrenceActions: ยืนยันทั้งหมด, then จ่ายแล้ว / ข้ามทั้งหมด).
class DueGroupHeader extends StatelessWidget {
  const DueGroupHeader({
    required this.label,
    this.caption,
    this.actions,
    super.key,
  });

  final String label;
  final String? caption;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.sm),
            actions!,
          ],
        ],
      ),
    );
  }
}

/// "ดูทั้ง 24 งวด" (the chevron is added): the rest of an item's due
/// occurrences.
class DueMoreRow extends StatelessWidget {
  const DueMoreRow({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(AppIcons.chevronRight, size: 16, color: accent),
          ],
        ),
      ),
    );
  }
}
