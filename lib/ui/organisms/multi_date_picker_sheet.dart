import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_chip.dart';
import '../atoms/app_icon.dart';
import '../atoms/ui_config.dart';
import '../tokens/app_spacing.dart';
import 'app_sheet.dart';

/// Opens [MultiDatePickerSheet] in the app's bottom sheet and resolves with
/// the confirmed dates (day-only, normalised to y / m / d), or null when
/// dismissed. Every word is the caller's ([title], [confirmLabel]); month and
/// weekday names follow the locale.
///
/// ```dart
/// final days = await showMultiDatePicker(context,
///     initial: picked, first: today, last: today.add(…≤ 2 years),
///     title: 'Pick the dates', confirmLabel: (n) => 'Use $n dates');
/// if (days != null) setState(() => picked = days);
/// ```
Future<Set<DateTime>?> showMultiDatePicker(
  BuildContext context, {
  required Set<DateTime> initial,
  required DateTime first,
  required DateTime last,
  required String title,
  required String Function(int count) confirmLabel,
  ValueChanged<Set<DateTime>>? onChanged,
}) {
  return showPpForgeSheetCustom<Set<DateTime>>(
    context,
    builder: (ctx) => MultiDatePickerSheet(
      initial: initial,
      first: first,
      last: last,
      title: title,
      confirmLabel: confirmLabel,
      onChanged: onChanged,
      onConfirm: (days) => Navigator.of(ctx).pop(days),
    ),
  );
}

/// A calendar where you pick SEVERAL days (a custom recurrence's hand-picked
/// dates) — the same look as [PpForgeDateRangePickerSheet]:
///
/// - ‹ month › navigation, kept inside [first] … [last];
/// - tap a day to toggle it; a picked day is highlighted (filled), never
///   ticked; days outside the bounds are dimmed and ignore taps;
/// - the picked days, in order, as removable chips under the calendar (a
///   tap anywhere on a chip drops it);
/// - a footer: Clear (with something picked) and the confirm, labelled by
///   [confirmLabel] with the count and off while nothing is picked.
///
/// Builds its own [PpForgeSheetScaffold] — open it with [showMultiDatePicker]
/// (or [showPpForgeSheetCustom]); to show it inline, give it a bounded height.
/// Dates are day-only: [initial] is normalised to y / m / d and days outside
/// the bounds are dropped. The caller keeps the span sensible (≤ 2 years).
class MultiDatePickerSheet extends StatefulWidget {
  const MultiDatePickerSheet({
    required this.initial,
    required this.first,
    required this.last,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.onChanged,
    super.key,
  });

  final Set<DateTime> initial;

  /// The earliest pickable day (inclusive).
  final DateTime first;

  /// The latest pickable day (inclusive).
  final DateTime last;
  final String title;

  /// The confirm button's label for the picked count ("Use 3 dates").
  final String Function(int count) confirmLabel;

  /// Every change of the picked set (toggle, chip ✕, clear).
  final ValueChanged<Set<DateTime>>? onChanged;

  /// The confirm: the picked days, normalised.
  final ValueChanged<Set<DateTime>> onConfirm;

  @override
  State<MultiDatePickerSheet> createState() => _MultiDatePickerSheetState();
}

class _MultiDatePickerSheetState extends State<MultiDatePickerSheet> {
  late DateTime _month;
  late Set<DateTime> _picked;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _first => _day(widget.first);
  DateTime get _last => _day(widget.last);

  bool _inBounds(DateTime d) => !d.isBefore(_first) && !d.isAfter(_last);

  @override
  void initState() {
    super.initState();
    _picked = {
      for (final d in widget.initial)
        if (_inBounds(_day(d))) _day(d),
    };
    final anchor = _picked.isEmpty
        ? _day(DateTime.now())
        : _picked.reduce((a, b) => a.isBefore(b) ? a : b);
    final clamped = anchor.isBefore(_first)
        ? _first
        : (anchor.isAfter(_last) ? _last : anchor);
    _month = DateTime(clamped.year, clamped.month);
  }

  bool get _canPrev => _month.isAfter(DateTime(_first.year, _first.month));

  bool get _canNext => _month.isBefore(DateTime(_last.year, _last.month));

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  void _set(Set<DateTime> next) {
    setState(() => _picked = next);
    widget.onChanged?.call({..._picked});
  }

  void _toggle(DateTime d) {
    final next = {..._picked};
    next.contains(d) ? next.remove(d) : next.add(d);
    _set(next);
  }

  void _remove(DateTime d) => _set({..._picked}..remove(d));

  @override
  Widget build(BuildContext context) {
    final strings = PpForgeConfig.stringsOf(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final loc = MaterialLocalizations.of(context);
    final firstDow = loc.firstDayOfWeekIndex;
    final lead =
        (DateTime(_month.year, _month.month).weekday % 7 - firstDow + 7) % 7;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final cells = ((lead + days + 6) ~/ 7) * 7;
    final sorted = _picked.toList()..sort();
    final thisYear = DateTime.now().year;
    String chipLabel(DateTime d) => d.year == thisYear
        ? loc.formatShortMonthDay(d)
        : '${loc.formatShortMonthDay(d)} ${loc.formatYear(d)}';

    return PpForgeSheetScaffold(
      title: widget.title,
      footer: Row(
        children: [
          if (_picked.isNotEmpty) ...[
            Expanded(
              child: PpForgeButton(
                label: strings.clear,
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _set(<DateTime>{}),
              ),
            ),
            const SizedBox(width: PpForgeSpacing.sm),
          ],
          Expanded(
            flex: 2,
            child: PpForgeButton(
              label: widget.confirmLabel(_picked.length),
              expand: true,
              onPressed: _picked.isEmpty
                  ? null
                  : () => widget.onConfirm({..._picked}),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PpForgeSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  tooltip: strings.monthPrev,
                  onPressed: _canPrev ? () => _shift(-1) : null,
                  icon: const PpForgeIcon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    loc.formatMonthYear(_month),
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: strings.monthNext,
                  onPressed: _canNext ? () => _shift(1) : null,
                  icon: const PpForgeIcon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        loc.narrowWeekdays[(firstDow + i) % 7],
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PpForgeSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
            child: Column(
              children: [
                for (var row = 0; row < cells ~/ 7; row++)
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: _cell(context, row * 7 + col - lead + 1, days),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PpForgeSpacing.lg,
              PpForgeSpacing.md,
              PpForgeSpacing.lg,
              PpForgeSpacing.sm,
            ),
            child: sorted.isEmpty
                ? Text(
                    strings.pickDatesHint,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Wrap(
                    spacing: PpForgeSpacing.sm,
                    runSpacing: PpForgeSpacing.sm,
                    children: [
                      for (final d in sorted)
                        PpForgeChip(
                          key: ValueKey(d),
                          label: chipLabel(d),
                          selected: true,
                          trailing: PpForgeChipTrailing.remove,
                          onRemove: () => _remove(d),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int n, int days) {
    if (n < 1 || n > days) return const SizedBox(height: 44);
    final scheme = Theme.of(context).colorScheme;
    final d = DateTime(_month.year, _month.month, n);
    final enabled = _inBounds(d);
    final picked = _picked.contains(d);
    final isToday = DateUtils.isSameDay(d, DateTime.now());
    return SizedBox(
      height: 44,
      child: InkResponse(
        onTap: enabled ? () => _toggle(d) : null,
        radius: 22,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: picked ? scheme.primary : null,
              shape: BoxShape.circle,
              border: isToday && !picked
                  ? Border.all(color: scheme.primary)
                  : null,
            ),
            child: Text(
              '$n',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: !enabled
                    ? scheme.onSurface.withValues(alpha: 0.38)
                    : (picked ? scheme.onPrimary : null),
                fontWeight: picked ? FontWeight.w600 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
