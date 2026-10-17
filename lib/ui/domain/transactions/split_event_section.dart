import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';

/// How [SplitEventSection] / [EventRow] lay out.
///
/// - [compact]: the QUICK forms (quick create, pending add / edit) — a
///   one-line green header with a chevron, rows like the Note row
///   ([DraftFieldRow]: muted label in a 72 px column, value to the right).
/// - [full]: the transaction detail — a [CollapsibleSection] (title + one-line
///   description, always open) with [DetailRow]s.
enum SplitEventVariant { compact, full }

/// A labelled row of a quick form — โน้ต, แบ่งยอด, อีเวนต์: the label in a
/// fixed column on the left ([labelWidthOf]) so every field lines up at the
/// same x. The column is as wide as the widest label of any such row (so no
/// label ever wraps, in any language or text size). [dense]: the value is a
/// chip, not an input: the row centres label and value vertically, so a value
/// that wraps onto a second line still sits in the middle of the row.
class DraftFieldRow extends StatelessWidget {
  const DraftFieldRow({
    required this.label,
    required this.child,
    this.dense = false,
    super.key,
  });

  final String label;
  final Widget child;
  final bool dense;

  /// Narrowest the label column gets.
  static const minLabelWidth = 72.0;

  /// The labels of every row that shares the column (the widest sets its
  /// width). Add a row's label here when it joins a form.
  static List<String> _labels(AppLocalizations l) => [
    l.commonNote,
    l.txSplitRowLabel,
    l.txSplitPeopleLabel,
    l.quickEventLabel,
    l.txRecurringRowLabel,
    l.debtCloseLabel,
  ];

  /// The label column's width: the widest shared label at the current font
  /// and text scale, never below [minLabelWidth].
  static double labelWidthOf(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var widest = minLabelWidth;
    for (final label in _labels(AppLocalizations.of(context)!)) {
      final p = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (p.width > widest) widest = p.width;
      p.dispose();
    }
    // A little air before the value.
    return widest.ceilToDouble() + AppSpacing.xs;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: dense
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidthOf(context),
          child: Padding(
            // An input's row: the label lines up with its first line.
            padding: EdgeInsets.only(top: dense ? 0 : 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// View mode: a long-press anywhere on a link row enters edit mode on it (the
/// chips' own taps still work: a tap is theirs, only a long-press is ours).
Widget longPressRow(Widget row, VoidCallback? onLongPress) => onLongPress == null
    ? row
    : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onLongPress,
        child: row,
      );

/// The event row of the section: what [SplitEventSection] needs to draw
/// "อีเวนต์ [🎉 name ✕]" — the name (null = none), a tap (open the picker,
/// or the event itself in view) and a ✕. [editing] false = view mode: the
/// chips are plain (a filled one opens the event), nothing is changed here;
/// [locked] = shown but not changeable (a plain chip, no tap, no ✕).
class SplitEventSlot {
  const SplitEventSlot({
    this.name,
    this.onTap,
    this.onClear,
    this.locked = false,
    this.editing = true,
    this.onLongPress,
  });

  final String? name;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool locked;
  final bool editing;

  /// View mode: a long-press on the row enters edit mode on this field.
  final VoidCallback? onLongPress;
}

/// The อีเวนต์ row of a transaction form's sections — "อีเวนต์  [🎉 name ✕]",
/// the same in quick create, the drafts and the detail page. The event is an
/// entity chip (event icon, people colour, name); empty with a [onTap] it is
/// the add chip "+ เพิ่มอีเวนต์" that opens the picker. Tapping the chip opens
/// the picker (or, in view, the event). [onClear] adds ✕. [locked]: a plain
/// chip without ✕ / tap (a row that can't change its event; no 🔒 — a solid
/// line already says "not editable"). Edit mode: a chip is dashed (changeable),
/// a chosen one also has the thin line inside. Empty and nothing to tap:
/// "ไม่ได้เลือก", muted.
class EventRow extends StatelessWidget {
  const EventRow({
    required this.name,
    this.onTap,
    this.onClear,
    this.locked = false,
    this.editing = true,
    this.onLongPress,
    this.variant = SplitEventVariant.full,
    super.key,
  });

  final String? name;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool locked;
  final bool editing;
  final VoidCallback? onLongPress;
  final SplitEventVariant variant;

  bool get _compact => variant == SplitEventVariant.compact;

  Widget _value(BuildContext context, AppLocalizations l) {
    final n = name;
    final accent = ModuleColors.of(context).people;
    if (n == null) {
      if (onTap == null || locked) {
        return DetailPlaceholder(l.quickEventNone);
      }
      // Empty and changeable: the dashed "+" chip, in view mode too (it says
      // there is something to add; a long-press there enters edit mode).
      return AppChip(
        icon: AppIcons.add,
        label: l.quickEventAdd,
        tone: AppChipTone.primary,
        selected: true,
        dashed: true,
        onTap: onTap,
      );
    }
    final removable = editing && !locked && onClear != null;
    final changeable = editing && !locked;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: LayoutBuilder(
            builder: (context, c) => AppChip(
              icon: AppIcons.project,
              color: accent,
              label: n,
              selected: changeable,
              dashed: changeable,
              inset: changeable,
              maxWidth: c.maxWidth.isFinite ? c.maxWidth : null,
              onTap: locked ? null : onTap,
              trailing: removable
                  ? AppChipTrailing.remove
                  : AppChipTrailing.none,
              onRemove: removable ? onClear : null,
              tooltip: removable ? l.quickEventRemove : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final value = _value(context, l);
    final Widget row = _compact
        ? DraftFieldRow(
            label: l.quickEventLabel,
            dense: true,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: value,
            ),
          )
        : DetailRow(
            label: l.quickEventLabel,
            trailing: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: value,
            ),
          );
    return longPressRow(row, onLongPress);
  }
}

/// The รายการประจำ row of the section (0.4.0): the recurring this transaction
/// is linked to — [name] (null = none), [periodLabel] ("งวด 16 ต.ค."), a tap
/// (open the picker, or the recurring in view), an optional ✕ ([onClear] —
/// only where the BE can unlink), [locked] (shown, not changeable), [editing]
/// (false = view mode, see [SplitEventSlot]) and [ask]: an inline question
/// shown under the row (an [AskCard]).
class SplitRecurringSlot {
  const SplitRecurringSlot({
    this.name,
    this.periodLabel,
    this.onTap,
    this.onClear,
    this.locked = false,
    this.editing = true,
    this.onLongPress,
    this.ask,
  });

  final String? name;
  final String? periodLabel;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool locked;
  final bool editing;
  final VoidCallback? onLongPress;
  final Widget? ask;
}

/// The รายการประจำ row — "รายการประจำ  [🔁 name · งวด 16 ต.ค. ✕]"; empty with
/// a tap it is the add chip "+ เลือกรายการประจำ"; nothing to tap: "ไม่ได้เลือก".
/// [variant] as [EventRow]; the [SplitRecurringSlot.ask] card sits under it.
class RecurringLinkRow extends StatelessWidget {
  const RecurringLinkRow({
    required this.slot,
    this.variant = SplitEventVariant.full,
    super.key,
  });

  final SplitRecurringSlot slot;
  final SplitEventVariant variant;

  bool get _compact => variant == SplitEventVariant.compact;

  Widget _value(BuildContext context, AppLocalizations l) {
    final n = slot.name;
    if (n == null) {
      if (slot.onTap == null || slot.locked) {
        return DetailPlaceholder(l.quickEventNone);
      }
      return AppChip(
        icon: AppIcons.add,
        label: l.txRecurringPick,
        tone: AppChipTone.primary,
        selected: true,
        dashed: true,
        onTap: slot.onTap,
      );
    }
    final changeable = slot.editing && !slot.locked;
    final removable = changeable && slot.onClear != null;
    final period = slot.periodLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: LayoutBuilder(
            builder: (context, c) => AppChip(
              icon: AppIcons.recurring,
              color: ModuleColors.of(context).planning,
              label: period == null ? n : '$n · $period',
              selected: changeable,
              dashed: changeable,
              inset: changeable,
              maxWidth: c.maxWidth.isFinite ? c.maxWidth : null,
              onTap: slot.locked ? null : slot.onTap,
              trailing: removable
                  ? AppChipTrailing.remove
                  : AppChipTrailing.none,
              onRemove: removable ? slot.onClear : null,
              tooltip: removable ? l.txRecurringUnlink : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final value = _value(context, l);
    final row = _compact
        ? DraftFieldRow(
            label: l.txRecurringRowLabel,
            dense: true,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: value,
            ),
          )
        : DetailRow(
            label: l.txRecurringRowLabel,
            trailing: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: value,
            ),
          );
    final ask = slot.ask;
    if (ask == null) return longPressRow(row, slot.onLongPress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        longPressRow(row, slot.onLongPress),
        Padding(
          padding: _compact
              ? const EdgeInsets.only(top: AppSpacing.xs)
              : const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
          child: ask,
        ),
      ],
    );
  }
}

/// THE split + event block of a transaction, built once and used by quick
/// create, the pending drafts ("เพิ่มร่าง" + "แก้ร่าง") and the transaction
/// detail. [variant] picks the look (see [SplitEventVariant]):
///
///   full                                              compact
///   แบ่งรายการ  (green heading)                       แบ่งรายการ            ⌄
///   แบ่งยอดให้คนอื่น หรือใส่ในอีเวนต์                  แบ่งยอด  [+ เพิ่มคน]
///   แบ่งยอด            [+ เพิ่มคน]                    (the people)
///   อีเวนต์                  [🎉 ทริป ✕]              อีเวนต์  [🎉 ทริป ✕]
///
/// No separators inside it. [splits] is the "แบ่งยอด" row (built by the
/// caller: the feature's split editor, or a read-only list); [event] the
/// อีเวนต์ row. Either may be null.
///
/// [collapsible]: the heading toggles it (pending: closed by default, quick
/// create: open by default); closed, [summary] ("แบ่ง 2 คน · ทริปเชียงใหม่",
/// or "ไม่ได้ตั้ง") shows under the title (full) / at the end of the heading
/// line (compact). The transaction detail is never collapsible.
///
/// [helper]: a small muted line under the event row (compact only: "this
/// split will live in the event …").
class SplitEventSection extends StatefulWidget {
  const SplitEventSection({
    this.splits,
    this.event,
    this.recurring,
    this.summary,
    this.collapsible = false,
    this.initiallyOpen = true,
    this.first = false,
    this.variant = SplitEventVariant.full,
    this.helper,
    super.key,
  });

  final Widget? splits;
  final SplitEventSlot? event;

  /// The รายการประจำ row (0.4.0), after the event; null = no such row.
  final SplitRecurringSlot? recurring;
  final String? summary;
  final bool collapsible;
  final bool initiallyOpen;

  /// No band above (the first section of a page).
  final bool first;
  final SplitEventVariant variant;
  final String? helper;

  @override
  State<SplitEventSection> createState() => _SplitEventSectionState();
}

class _SplitEventSectionState extends State<SplitEventSection> {
  late bool _open = !widget.collapsible || widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = widget.event;
    final compact = widget.variant == SplitEventVariant.compact;
    if (!compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.first) const SizedBox(height: AppSpacing.lg),
          CollapsibleSection(
            title: l.txSplitSectionTitle,
            hint: l.txSplitSectionHint,
            summary: widget.summary ?? l.draftExtrasNone,
            collapsible: widget.collapsible,
            initiallyOpen: widget.initiallyOpen,
            children: [
              ?widget.splits,
              if (e != null)
                EventRow(
                  name: e.name,
                  onTap: e.onTap,
                  onClear: e.onClear,
                  locked: e.locked,
                  editing: e.editing,
                  onLongPress: e.onLongPress,
                ),
              if (widget.recurring != null)
                RecurringLinkRow(slot: widget.recurring!),
            ],
          ),
        ],
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final open = !widget.collapsible || _open;
    final header = Row(
      children: [
        Expanded(
          child: Text(
            l.txSplitSectionTitle,
            style: text.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!open) ...[
          Flexible(
            child: Text(
              widget.summary ?? l.draftExtrasNone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (widget.collapsible)
          AnimatedRotation(
            turns: open ? 0.5 : 0,
            duration: const Duration(milliseconds: 160),
            child: AppIcon(AppIcons.expand, color: scheme.onSurfaceVariant),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.first) const SizedBox(height: AppSpacing.lg),
        InkWell(
          onTap: widget.collapsible
              ? () => setState(() => _open = !_open)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: header,
          ),
        ),
        if (open) ...[
          if (widget.splits != null) ...[
            const SizedBox(height: AppSpacing.xs),
            widget.splits!,
          ],
          if (e != null) ...[
            const SizedBox(height: AppSpacing.xs),
            EventRow(
              name: e.name,
              onTap: e.onTap,
              onClear: e.onClear,
              locked: e.locked,
              editing: e.editing,
              onLongPress: e.onLongPress,
              variant: SplitEventVariant.compact,
            ),
          ],
          if (widget.recurring != null) ...[
            const SizedBox(height: AppSpacing.xs),
            RecurringLinkRow(
              slot: widget.recurring!,
              variant: SplitEventVariant.compact,
            ),
          ],
          if (widget.helper != null)
            Padding(
              padding: EdgeInsets.only(
                left: DraftFieldRow.labelWidthOf(context),
                top: AppSpacing.xs,
              ),
              child: Text(
                widget.helper!,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ],
    );
  }
}
