import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../tx_list_filters.dart';

/// "ช่วงเวลา" — pick a [TxPeriod] in a sheet (the transactions list's
/// period pill; the dashboard may adopt it). Null when dismissed.
Future<TxPeriod?> showPeriodSheet(
  BuildContext context, {
  required TxPeriod current,
}) {
  final l = AppLocalizations.of(context)!;
  return showAppSheet<TxPeriod>(
    context,
    title: l.transactionsFilterRange,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: PeriodPicker(
        initial: current,
        onPicked: (p) => Navigator.of(ctx).pop(p),
      ),
    ),
  );
}

/// The unit, then a picker that follows it (owner 2026-10-10):
///
///   [วัน] [สัปดาห์] [เดือน] [ปี] [ทั้งหมด] [กำหนดเอง]
///   วัน → a calendar · สัปดาห์ → a calendar, any day picks its whole
///   week (Monday first, as the app) · เดือน → the month grid · ปี → a
///   year grid · ทั้งหมด → at once · กำหนดเอง → the range picker.
///
/// A pick calls [onPicked]; nothing past [last] (default today).
class PeriodPicker extends StatefulWidget {
  const PeriodPicker({
    required this.initial,
    required this.onPicked,
    this.last,
    super.key,
  });

  final TxPeriod initial;
  final ValueChanged<TxPeriod> onPicked;
  final DateTime? last;

  @override
  State<PeriodPicker> createState() => _PeriodPickerState();
}

class _PeriodPickerState extends State<PeriodPicker> {
  late TxPeriodKind _unit = widget.initial.kind;

  static final _first = DateTime(2000);

  DateTime get _last {
    final l = widget.last ?? DateTime.now();
    return DateTime(l.year, l.month, l.day);
  }

  /// Where the pickers open: the current period's first day (today for
  /// ทั้งหมด), never past [_last].
  DateTime get _anchor {
    final p = widget.initial;
    final d = p.kind == TxPeriodKind.all ? _last : p.start;
    return d.isAfter(_last) ? _last : d;
  }

  Future<void> _pickRange() async {
    final p = widget.initial;
    final range = await showDateRangePicker(
      context: context,
      firstDate: _first,
      lastDate: _last,
      initialDateRange: p.kind == TxPeriodKind.all
          ? null
          : DateTimeRange(
              start: p.start.isAfter(_last) ? _last : p.start,
              end: p.last!.isAfter(_last) ? _last : p.last!,
            ),
    );
    if (range == null || !mounted) return;
    widget.onPicked(TxPeriod.custom(range.start, range.end));
  }

  void _onUnit(TxPeriodKind k) {
    switch (k) {
      case TxPeriodKind.all:
        widget.onPicked(TxPeriod.all);
      case TxPeriodKind.custom:
        setState(() => _unit = k);
        _pickRange();
      default:
        setState(() => _unit = k);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget calendar(TxPeriod Function(DateTime) to) => CalendarDatePicker(
      initialDate: _anchor,
      firstDate: _first,
      lastDate: _last,
      onDateChanged: (d) => widget.onPicked(to(d)),
    );
    final picker = switch (_unit) {
      TxPeriodKind.day => calendar(TxPeriod.day),
      TxPeriodKind.week => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.txPeriodWeekHint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          calendar(TxPeriod.week),
        ],
      ),
      TxPeriodKind.month => MonthPickerGrid(
        selected: _anchor,
        last: _last,
        onPicked: (m) => widget.onPicked(TxPeriod.month(m)),
      ),
      TxPeriodKind.year => SizedBox(
        height: 280,
        child: YearPicker(
          firstDate: _first,
          lastDate: _last,
          selectedDate: _anchor,
          onChanged: (d) => widget.onPicked(TxPeriod.year(d)),
        ),
      ),
      // At once (ทั้งหมด) / in the range picker (กำหนดเอง).
      TxPeriodKind.all || TxPeriodKind.custom => const SizedBox.shrink(),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoicePillRow<TxPeriodKind>(
          values: const [
            TxPeriodKind.day,
            TxPeriodKind.week,
            TxPeriodKind.month,
            TxPeriodKind.year,
            TxPeriodKind.all,
            TxPeriodKind.custom,
          ],
          selected: _unit,
          label: (k) => txPeriodUnitLabel(l, k),
          onSelected: _onUnit,
          // Picking กำหนดเอง / ทั้งหมด again still acts.
          reselect: (k) => k == TxPeriodKind.custom || k == TxPeriodKind.all,
        ),
        const SizedBox(height: AppSpacing.sm),
        picker,
      ],
    );
  }
}

/// A period unit's short name — "วัน", "สัปดาห์", …
String txPeriodUnitLabel(AppLocalizations l, TxPeriodKind k) => switch (k) {
  TxPeriodKind.day => l.txPeriodDay,
  TxPeriodKind.week => l.txPeriodWeek,
  TxPeriodKind.month => l.txPeriodMonth,
  TxPeriodKind.year => l.txPeriodYear,
  TxPeriodKind.all => l.transactionsRangeAll,
  TxPeriodKind.custom => l.txPeriodCustom,
};
