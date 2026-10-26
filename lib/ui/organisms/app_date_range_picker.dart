import '../atoms/app_icon_button.dart';
import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';
import '../tokens/app_spacing.dart';

/// A named range [AppDatePicker.range] offers above its calendar.
class AppDateRangePreset {
  const AppDateRangePreset(this.label, this.range);
  final String label;
  final DateTimeRange range;
}

class AppDateRangePickerSheet extends StatefulWidget {
  const AppDateRangePickerSheet({
    required this.first,
    required this.last,
    required this.onResult,
    this.initial,
    this.presets = const [],
    super.key,
  });

  final DateTimeRange? initial;
  final DateTime first;
  final DateTime last;
  final List<AppDateRangePreset> presets;
  final ValueChanged<DateTimeRange> onResult;

  @override
  State<AppDateRangePickerSheet> createState() =>
      _AppDateRangePickerSheetState();
}

class _AppDateRangePickerSheetState extends State<AppDateRangePickerSheet> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _start = widget.initial == null ? null : _day(widget.initial!.start);
    _end = widget.initial == null ? null : _day(widget.initial!.end);
    final anchor = _start ?? _day(DateTime.now());
    final clamped = anchor.isBefore(widget.first)
        ? widget.first
        : (anchor.isAfter(widget.last) ? widget.last : anchor);
    _month = DateTime(clamped.year, clamped.month);
  }

  bool get _canPrev => DateTime(
    _month.year,
    _month.month,
  ).isAfter(DateTime(widget.first.year, widget.first.month));

  bool get _canNext => DateTime(
    _month.year,
    _month.month,
  ).isBefore(DateTime(widget.last.year, widget.last.month));

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  void _tap(DateTime d) {
    setState(() {
      if (_start == null || _end != null) {
        _start = d;
        _end = null;
      } else if (d.isBefore(_start!)) {
        _end = _start;
        _start = d;
      } else {
        _end = d;
      }
    });
  }

  bool _enabled(DateTime d) =>
      !d.isBefore(_day(widget.first)) && !d.isAfter(_day(widget.last));

  @override
  Widget build(BuildContext context) {
    final strings = UiConfig.stringsOf(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final loc = MaterialLocalizations.of(context);
    final firstDow = loc.firstDayOfWeekIndex;
    final lead =
        (DateTime(_month.year, _month.month).weekday % 7 - firstDow + 7) % 7;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final cells = ((lead + days + 6) ~/ 7) * 7;
    final end = _end ?? _start;
    String fmt(DateTime? d) => d == null ? '—' : loc.formatShortDate(d);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.presets.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: widget.presets.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final p = widget.presets[i];
                return ActionChip(
                  label: Text(p.label),
                  onPressed: () => setState(() {
                    _start = _day(p.range.start);
                    _end = _day(p.range.end);
                    _month = DateTime(_start!.year, _start!.month);
                  }),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              AppIconButton.flat(
                tooltip: strings.periodPrev,
                onPressed: _canPrev ? () => _shift(-1) : null,
                icon: Icons.chevron_left,
              ),
              Expanded(
                child: Text(
                  loc.formatMonthYear(_month),
                  textAlign: TextAlign.center,
                  style: text.titleMedium,
                ),
              ),
              AppIconButton.flat(
                tooltip: strings.periodNext,
                onPressed: _canNext ? () => _shift(1) : null,
                icon: Icons.chevron_right,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (var row = 0; row < cells ~/ 7; row++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _cell(
                          context,
                          row * 7 + col - lead + 1,
                          days,
                          end,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${fmt(_start)}  →  ${fmt(end)}',
                  style: text.bodyLarge,
                ),
              ),
              AppButton(
                label: strings.save,
                onPressed: _start == null
                    ? null
                    : () => widget.onResult(
                        DateTimeRange(start: _start!, end: end!),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, int n, int days, DateTime? end) {
    if (n < 1 || n > days) return const SizedBox(height: 44);
    final scheme = Theme.of(context).colorScheme;
    final d = DateTime(_month.year, _month.month, n);
    final enabled = _enabled(d);
    final isStart = _start != null && d == _start;
    final isEnd = end != null && d == end;
    final inside =
        _start != null &&
        end != null &&
        !d.isBefore(_start!) &&
        !d.isAfter(end);
    final edge = isStart || isEnd;
    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: enabled ? () => _tap(d) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: edge
                ? scheme.primary
                : (inside ? scheme.primaryContainer : null),
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(isStart || !inside ? 22 : 0),
              right: Radius.circular(isEnd || !inside ? 22 : 0),
            ),
          ),
          child: Text(
            '$n',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: !enabled
                  ? scheme.onSurface.withValues(alpha: 0.38)
                  : (edge ? scheme.onPrimary : null),
            ),
          ),
        ),
      ),
    );
  }
}
