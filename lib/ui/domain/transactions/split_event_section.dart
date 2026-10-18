import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';

enum SplitEventVariant { compact, full }

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

  static const minLabelWidth = 72.0;

  static List<String> _labels(AppLocalizations l) => [
    l.commonNote,
    l.txSplitRowLabel,
    l.txSplitPeopleLabel,
    l.quickEventLabel,
    l.txRecurringRowLabel,
    l.debtCloseLabel,
  ];

  /// The label column's width: the widest shared label at the current font and
  /// text scale, never below [minLabelWidth].
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

Widget _longPressRow(Widget row, VoidCallback? onLongPress) =>
    onLongPress == null
    ? row
    : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onLongPress,
        child: row,
      );

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

  final VoidCallback? onLongPress;
}

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
    return _longPressRow(row, onLongPress);
  }
}

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
    if (ask == null) return _longPressRow(row, slot.onLongPress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _longPressRow(row, slot.onLongPress),
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

  final SplitRecurringSlot? recurring;
  final String? summary;
  final bool collapsible;
  final bool initiallyOpen;

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
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
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
