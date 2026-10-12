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
/// fixed column on the left ([labelWidth]) so every field lines up at the
/// same x. [dense]: the value is a 28 px chip, not a 40 px input, so the label
/// sits higher to meet the chip's middle.
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

  static const labelWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            // Lines up with the first line of a field / chip beside it.
            padding: EdgeInsets.only(top: dense ? 4 : 10),
            child: Text(
              label,
              maxLines: 2,
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

/// The event row of the section: what [SplitEventSection] needs to draw
/// "อีเวนต์ [🎉 name ✕]" — the name (null = none), a tap (open the picker,
/// or the event itself in view), a ✕ and the lock.
class SplitEventSlot {
  const SplitEventSlot({
    this.name,
    this.onTap,
    this.onClear,
    this.locked = false,
  });

  final String? name;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool locked;
}

/// The อีเวนต์ row of a transaction form's sections — "อีเวนต์  [🎉 name ✕]",
/// the same in quick create, the drafts and the detail page. The event is an
/// entity chip (event icon, people colour, name); empty with a [onTap] it is
/// the add chip "+ เพิ่มอีเวนต์" that opens the picker. Tapping the chip opens
/// the picker (or, in view, the event). [onClear] adds ✕. [locked]: the chip
/// without ✕ / tap and a 🔒 (a row that can't change its event). Empty and
/// nothing to tap: "ไม่ได้เลือก", muted.
class EventRow extends StatelessWidget {
  const EventRow({
    required this.name,
    this.onTap,
    this.onClear,
    this.locked = false,
    this.variant = SplitEventVariant.full,
    super.key,
  });

  final String? name;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool locked;
  final SplitEventVariant variant;

  bool get _compact => variant == SplitEventVariant.compact;

  Widget _value(BuildContext context, AppLocalizations l) {
    final n = name;
    final accent = ModuleColors.of(context).people;
    if (n == null) {
      if (onTap == null || locked) {
        return DetailPlaceholder(l.quickEventNone);
      }
      return AppChip(
        icon: AppIcons.add,
        label: l.quickEventAdd,
        tone: AppChipTone.primary,
        selected: true,
        dashed: _compact,
        size: _compact ? ChipSize.chip : ChipSize.control,
        onTap: onTap,
      );
    }
    final removable = !locked && onClear != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: LayoutBuilder(
            builder: (context, c) => AppChip(
              icon: AppIcons.project,
              color: accent,
              label: n,
              size: ChipSize.chip,
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
        if (locked) ...[
          const SizedBox(width: AppSpacing.xs),
          const AppIcon(AppIcons.lock),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final value = _value(context, l);
    if (_compact) {
      return DraftFieldRow(
        label: l.quickEventLabel,
        dense: true,
        child: Align(alignment: AlignmentDirectional.centerStart, child: value),
      );
    }
    return DetailRow(
      label: l.quickEventLabel,
      trailing: Align(alignment: AlignmentDirectional.centerEnd, child: value),
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
                ),
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
              variant: SplitEventVariant.compact,
            ),
          ],
          if (widget.helper != null)
            Padding(
              padding: const EdgeInsets.only(
                left: DraftFieldRow.labelWidth,
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
