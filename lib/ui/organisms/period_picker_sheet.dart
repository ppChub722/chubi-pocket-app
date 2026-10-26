import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../molecules/month_picker.dart';
import '../tokens/app_spacing.dart';
import 'app_date_picker.dart';

enum PeriodUnit { day, week, month, year, all, custom }

@immutable
class PeriodPick {
  const PeriodPick(this.unit, this.start, [this.end]);

  final PeriodUnit unit;
  final DateTime start;
  final DateTime? end;
}

/// The words of [PeriodPickerSheet] — the caller passes its localised strings
/// (the kit never reads the app's l10n).
class PeriodPickerLabels {
  const PeriodPickerLabels({
    required this.title,
    required this.weekHint,
    required this.day,
    required this.week,
    required this.month,
    required this.year,
    required this.all,
    required this.custom,
  });

  final String title;

  final String weekHint;
  final String day;
  final String week;
  final String month;
  final String year;
  final String all;
  final String custom;

  String of(PeriodUnit u) => switch (u) {
    PeriodUnit.day => day,
    PeriodUnit.week => week,
    PeriodUnit.month => month,
    PeriodUnit.year => year,
    PeriodUnit.all => all,
    PeriodUnit.custom => custom,
  };
}

/// The body of [AppDatePicker.period].
class PeriodPickerSheet extends StatefulWidget {
  const PeriodPickerSheet({
    required this.current,
    required this.labels,
    required this.onPicked,
    this.last,
    super.key,
  });

  final PeriodPick current;
  final PeriodPickerLabels labels;
  final ValueChanged<PeriodPick> onPicked;
  final DateTime? last;

  @override
  State<PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends State<PeriodPickerSheet> {
  late PeriodUnit _unit = widget.current.unit;

  static final _first = DateTime(2000);

  DateTime get _last {
    final l = widget.last ?? DateTime.now();
    return DateTime(l.year, l.month, l.day);
  }

  /// Where the pickers open: the current pick's start (today for "all"), never
  /// past [_last].
  DateTime get _anchor {
    final p = widget.current;
    final d = p.unit == PeriodUnit.all ? _last : p.start;
    return d.isAfter(_last) ? _last : d;
  }

  Future<void> _pickRange() async {
    final p = widget.current;
    final end = p.end ?? p.start;
    final range = await AppDatePicker.range(
      context,
      first: _first,
      last: _last,
      initial: p.unit == PeriodUnit.all
          ? null
          : DateTimeRange(
              start: p.start.isAfter(_last) ? _last : p.start,
              end: end.isAfter(_last) ? _last : end,
            ),
    );
    if (range == null || !mounted) return;
    widget.onPicked(PeriodPick(PeriodUnit.custom, range.start, range.end));
  }

  void _onUnit(PeriodUnit u) {
    switch (u) {
      case PeriodUnit.all:
        widget.onPicked(PeriodPick(PeriodUnit.all, _last));
      case PeriodUnit.custom:
        setState(() => _unit = u);
        _pickRange();
      default:
        setState(() => _unit = u);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget calendar(PeriodUnit unit) => CalendarDatePicker(
      initialDate: _anchor,
      firstDate: _first,
      lastDate: _last,
      onDateChanged: (d) => widget.onPicked(PeriodPick(unit, d)),
    );
    final picker = switch (_unit) {
      PeriodUnit.day => calendar(PeriodUnit.day),
      PeriodUnit.week => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.labels.weekHint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          calendar(PeriodUnit.week),
        ],
      ),
      PeriodUnit.month => MonthPickerGrid(
        selected: _anchor,
        last: _last,
        onPicked: (m) => widget.onPicked(PeriodPick(PeriodUnit.month, m)),
      ),
      PeriodUnit.year => SizedBox(
        height: 280,
        child: YearPicker(
          firstDate: _first,
          lastDate: _last,
          selectedDate: _anchor,
          onChanged: (d) => widget.onPicked(PeriodPick(PeriodUnit.year, d)),
        ),
      ),
      PeriodUnit.all || PeriodUnit.custom => const SizedBox.shrink(),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final u in PeriodUnit.values)
              AppChip(
                label: widget.labels.of(u),
                selected: u == _unit,
                onTap: () {
                  if (u != _unit ||
                      u == PeriodUnit.custom ||
                      u == PeriodUnit.all) {
                    _onUnit(u);
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        picker,
      ],
    );
  }
}
