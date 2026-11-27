import 'package:flutter/material.dart';

import 'package:ppforge_core/ui.dart';
import '../tokens/app_icons.dart';

/// The next occurrence as one slim row inside an item's hero (0.4.3 plan E):
/// "งวดถัดไป (6/12) | อีก 12 วัน" and its amount (or [amountText] in
/// [amountColor] when it has none yet). A tap edits this occurrence.
class HeroNextOccurrence extends StatelessWidget {
  const HeroNextOccurrence({
    required this.label,
    this.amount,
    this.amountText,
    this.amountColor,
    this.onTap,
    this.icon = AppIcons.date,
    super.key,
  });

  final String label;

  /// The leading glyph (a date by default).
  final IconData icon;
  final Widget? amount;
  final String? amountText;
  final Color? amountColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final value = amount ?? (amountText == null ? null : Text(amountText!));
    return BusyLock(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PpForgeRadius.lg),
          child: HeroInsetBox(
            padding: const EdgeInsets.symmetric(
              horizontal: PpForgeSpacing.md,
              vertical: PpForgeSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: PpForgeSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: PpForgeSpacing.sm),
                  DefaultTextStyle.merge(
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                    child: value,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "ต้องจัดการ": the occurrences that are due (or still need an amount), in
/// one card edged and washed in the warning colour.
/// [children]: a [DueSelectBar] first when rows can be picked, then
/// OccurrenceRows and [DueMoreRow]s. With [onToggle] it
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
    final warning = Theme.of(context).extension<PpForgeColors>()!.warning;
    final shown = open || onToggle == null;
    final head = Padding(
      padding: EdgeInsets.fromLTRB(
        PpForgeSpacing.lg,
        PpForgeSpacing.md,
        onToggle == null ? PpForgeSpacing.lg : PpForgeSpacing.md,
        shown ? PpForgeSpacing.xs : PpForgeSpacing.md,
      ),
      child: Row(
        children: [
          Icon(AppIcons.warning, size: 18, color: warning),
          const SizedBox(width: PpForgeSpacing.xs),
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
            const SizedBox(width: PpForgeSpacing.xs),
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
        borderRadius: BorderRadius.circular(PpForgeRadius.lg),
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
                child: BusyLock(
                  child: InkWell(onTap: onToggle, child: head),
                ),
              ),
            if (shown) ...[
              ...children,
              const SizedBox(height: PpForgeSpacing.xs),
            ],
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
    this.paidLabel,
    this.onPaid,
    this.heading = false,
    this.open = true,
    this.onToggle,
    super.key,
  });

  /// จ่ายแล้วที่เลือก, between ข้าม and ยืนยัน (with [onPaid]).
  final String? paidLabel;
  final VoidCallback? onPaid;

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
        // The same start as an PpForgeListRow: its check sits over the rows'.
        padding: const EdgeInsets.fromLTRB(
          PpForgeSpacing.lg,
          PpForgeSpacing.xs,
          PpForgeSpacing.lg,
          PpForgeSpacing.sm,
        ),
        child: LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              Expanded(
                child: BusyLock(
                  child: InkWell(
                    key: const ValueKey('dueSelectAll'),
                    onTap: onSelectAll,
                    borderRadius: BorderRadius.circular(PpForgeRadius.sm),
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
                        const SizedBox(width: PpForgeSpacing.xs),
                        Flexible(
                          child: Text(
                            selectLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: heading
                                ? Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)
                                : Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                      ],
                    ),
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
                      PpForgeButton(
                        kind: ButtonIconKind.skip,
                        key: const ValueKey('dueSkipSelected'),
                        label: skipLabel,
                        onPressed: any ? onSkip : null,
                        submits: true,
                        variant: PpForgeButtonVariant.outlined,
                        size: PpForgeButtonSize.chip,
                      ),
                      if (paidLabel != null && onPaid != null) ...[
                        const SizedBox(width: PpForgeSpacing.sm),
                        PpForgeButton(
                          kind: ButtonIconKind.paid,
                          key: const ValueKey('duePaidSelected'),
                          label: paidLabel!,
                          onPressed: any ? onPaid : null,
                          submits: true,
                          variant: PpForgeButtonVariant.outlined,
                          size: PpForgeButtonSize.chip,
                        ),
                      ],
                      const SizedBox(width: PpForgeSpacing.sm),
                      PpForgeButton(
                        kind: ButtonIconKind.confirm,
                        key: const ValueKey('dueConfirmSelected'),
                        label: confirmLabel,
                        onPressed: any ? onConfirm : null,
                        submits: true,
                        size: PpForgeButtonSize.chip,
                      ),
                    ],
                  ),
                ),
              ),
              if (onToggle != null)
                Semantics(
                  button: true,
                  expanded: open,
                  child: BusyLock(
                    child: InkResponse(
                      key: const ValueKey('dueSectionFold'),
                      onTap: onToggle,
                      radius: 18,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: PpForgeSpacing.xs,
                        ),
                        child: Icon(
                          open ? AppIcons.collapse : AppIcons.expand,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
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

/// "ดูทั้ง 24 งวด" (the chevron is added): the rest of an item's due
/// occurrences.
class DueMoreRow extends StatelessWidget {
  const DueMoreRow({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return BusyLock(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PpForgeSpacing.sm),
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
      ),
    );
  }
}
