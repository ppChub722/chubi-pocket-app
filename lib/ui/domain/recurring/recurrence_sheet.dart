import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../atoms/app_button.dart';
import '../../atoms/app_chip.dart';
import '../../atoms/app_input.dart';
import '../../atoms/app_input_type.dart';
import '../../atoms/app_text.dart';
import '../../atoms/input_formatters.dart';
import '../../atoms/ui_config.dart';
import '../../molecules/day_of_month_picker.dart';
import '../../molecules/month_picker.dart';
import '../../organisms/app_date_picker.dart';
import '../../organisms/app_sheet.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/typography.dart';
import 'recurrence_rule.dart';
import 'recurrence_text.dart';

Future<RecurrenceRule?> showRecurrenceSheet(
  BuildContext context, {
  required RecurrenceRule initial,
  bool simple = false,
}) {
  return showAppSheetCustom<RecurrenceRule>(
    context,
    builder: (_) => _RecurrenceSheet(initial: initial, simple: simple),
  );
}

class _RecurrenceSheet extends StatefulWidget {
  const _RecurrenceSheet({required this.initial, required this.simple});

  final RecurrenceRule initial;
  final bool simple;

  @override
  State<_RecurrenceSheet> createState() => _RecurrenceSheetState();
}

class _RecurrenceSheetState extends State<_RecurrenceSheet> {
  late RecurrenceRule _rule = RecurrenceEditor.normalize(widget.initial);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final strings = UiConfig.stringsOf(context);
    return AppSheetScaffold(
      title: l.recurSheetTitle,
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: strings.cancel,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: l.commonOk,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(context).pop(_rule),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: RecurrenceEditor(
          initial: widget.initial,
          simple: widget.simple,
          onChanged: (r) => _rule = r,
        ),
      ),
    );
  }
}

class RecurrenceEditor extends StatefulWidget {
  const RecurrenceEditor({
    required this.initial,
    required this.onChanged,
    this.simple = false,
    super.key,
  });

  final RecurrenceRule initial;

  final bool simple;

  final ValueChanged<RecurrenceRule> onChanged;

  static const endSpanYears = 2;

  static RecurrenceRule normalize(RecurrenceRule r) {
    final dates = r.freq == RecurrenceFreq.dates;
    return r.copyWith(
      freq: dates ? RecurrenceFreq.monthly : null,
      dates: dates ? const [] : null,
      interval: r.interval < 1 ? 1 : r.interval,
    );
  }

  @override
  State<RecurrenceEditor> createState() => _RecurrenceEditorState();
}

class _RecurrenceEditorState extends State<RecurrenceEditor> {
  static const _units = [
    RecurrenceFreq.daily,
    RecurrenceFreq.weekly,
    RecurrenceFreq.monthly,
    RecurrenceFreq.yearly,
  ];

  late RecurrenceRule _rule;

  /// The start the sheet opened with; a moved start is always worked out
  /// from here, so picking the old day again puts it back.
  late DateTime _base;
  late RecurrenceFreq _freq;
  late int _interval;
  late Set<int> _weekdays;
  late int _startWeekday;
  late RecurrenceMonthlyMode _monthlyMode;
  late int _monthDay;
  late int _nth;
  late int _nthWeekday;
  late int _yearMonth;
  late int _yearDay;
  late RecurrenceEndKind _endKind;
  late DateTime _endDate;
  late int _endCount;
  late final TextEditingController _intervalText;
  late final TextEditingController _countText;

  DateTime get _start => _rule.start;

  DateTime get _lastEnd => DateTime(
    _start.year + RecurrenceEditor.endSpanYears,
    _start.month,
    _start.day,
  );

  @override
  void initState() {
    super.initState();
    _rule = RecurrenceEditor.normalize(widget.initial);
    final start = DateTime(_start.year, _start.month, _start.day);
    _base = start;
    _freq = _rule.freq;
    _interval = _rule.interval.clamp(1, 99);
    _weekdays = {
      for (final d in _rule.weekdays)
        if (d >= 1 && d <= 7) d,
    };
    if (_weekdays.isEmpty) _weekdays = {start.weekday};
    _startWeekday = start.weekday;
    _yearMonth = start.month;
    _yearDay = start.day.clamp(1, _daysIn(start.month));

    final m = _rule.monthly;
    _monthlyMode = m?.mode ?? RecurrenceMonthlyMode.day;
    final day = (m?.mode == RecurrenceMonthlyMode.day ? m?.day : null);
    _monthDay = (day ?? start.day).clamp(1, RecurrenceMonthly.lastDay);
    final weekdayMode = m?.mode == RecurrenceMonthlyMode.weekday;
    final startNth = (start.day - 1) ~/ 7 + 1;
    _nth = (weekdayMode ? m?.nth : null) ?? startNth;
    if (_nth >= 5) _nth = RecurrenceMonthly.lastWeek;
    _nthWeekday = (weekdayMode ? m?.weekday : null) ?? start.weekday;

    final end = _rule.end;
    _endKind = end.kind;
    final date = end.date;
    _endDate = date == null
        ? DateTime(start.year, start.month + 1, start.day)
        : DateTime(date.year, date.month, date.day);
    if (_endDate.isBefore(start)) _endDate = start;
    if (_endDate.isAfter(_lastEnd)) _endDate = _lastEnd;
    _endCount = (end.count ?? 12).clamp(1, 999);

    _intervalText = TextEditingController(text: '$_interval');
    _countText = TextEditingController(text: '$_endCount');
  }

  @override
  void dispose() {
    _intervalText.dispose();
    _countText.dispose();
    super.dispose();
  }

  /// Days in [month] of a common year: a yearly day never lands on 29 Feb.
  static int _daysIn(int month) => DateTime(2001, month + 1, 0).day;

  /// Where the first round lands. A yearly rule repeats on its start, and a
  /// budget's periods (simple) start on the picked weekday or day, so both
  /// move the start to the next such day on or after [_base].
  DateTime _anchoredStart() {
    final b = _base;
    if (_freq == RecurrenceFreq.yearly) {
      final d = DateTime(b.year, _yearMonth, _yearDay);
      return d.isBefore(b) ? DateTime(b.year + 1, _yearMonth, _yearDay) : d;
    }
    if (!widget.simple) return b;
    switch (_freq) {
      case RecurrenceFreq.weekly:
        return DateTime(
          b.year,
          b.month,
          b.day + (_startWeekday - b.weekday) % 7,
        );
      case RecurrenceFreq.monthly:
        for (var k = 0; k < 12; k++) {
          final last = DateTime(b.year, b.month + k + 1, 0).day;
          final day = _monthDay >= RecurrenceMonthly.lastDay ? last : _monthDay;
          if (day > last) continue;
          final d = DateTime(b.year, b.month + k, day);
          if (!d.isBefore(b)) return d;
        }
        return b;
      default:
        return b;
    }
  }

  RecurrenceRule _build() => RecurrenceRule(
    freq: _freq,
    start: _anchoredStart(),
    interval: _interval,
    weekdays: _freq == RecurrenceFreq.weekly && !widget.simple
        ? {..._weekdays}
        : const {},
    monthly: _freq != RecurrenceFreq.monthly || widget.simple
        ? null
        : (_monthlyMode == RecurrenceMonthlyMode.day
              ? RecurrenceMonthly.onDay(_monthDay)
              : RecurrenceMonthly.onWeekday(nth: _nth, weekday: _nthWeekday)),
    end: switch (_endKind) {
      RecurrenceEndKind.never => const RecurrenceEnd.never(),
      RecurrenceEndKind.onDate => RecurrenceEnd.onDate(_endDate),
      RecurrenceEndKind.afterCount => RecurrenceEnd.afterCount(_endCount),
    },
  );

  void _edit(VoidCallback change) {
    setState(() {
      change();
      final start = _anchoredStart();
      if (_endDate.isBefore(start)) _endDate = start;
      _rule = _build();
    });
    widget.onChanged(_rule);
  }

  void _toggleWeekday(int d) {
    if (_weekdays.contains(d) && _weekdays.length == 1) return;
    _edit(() {
      _weekdays = {..._weekdays};
      _weekdays.contains(d) ? _weekdays.remove(d) : _weekdays.add(d);
    });
  }

  Future<void> _pickEndDate() async {
    final start = DateTime(_start.year, _start.month, _start.day);
    final r = await showAppDatePicker(
      context,
      initial: _endDate,
      first: start,
      last: _lastEnd,
    );
    if (r is AppDatePicked && mounted) {
      final d = r.date;
      _edit(() => _endDate = DateTime(d.year, d.month, d.day));
    }
  }

  String _unitLabel(AppLocalizations l, RecurrenceFreq f) => switch (f) {
    RecurrenceFreq.daily => l.recurSheetUnitDay(_interval),
    RecurrenceFreq.weekly => l.recurSheetUnitWeek(_interval),
    RecurrenceFreq.monthly => l.recurSheetUnitMonth(_interval),
    _ => l.recurSheetUnitYear(_interval),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final strings = UiConfig.stringsOf(context);
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(title, role: AppTextRole.caption),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );

    Widget chips(List<Widget> children) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children,
    );

    Widget numberField(
      TextEditingController c,
      int max,
      ValueChanged<int> onValue,
    ) => SizedBox(
      width: 72,
      child: AppInput(
        controller: c,
        dense: true,
        type: AppInputType.number,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [RangeInputFormatter(1, max)],
        onChanged: (t) {
          final n = int.tryParse(t);
          if (n != null && n >= 1 && n <= max) onValue(n);
        },
      ),
    );

    final firstDow = loc.firstDayOfWeekIndex; // 0 = Sunday
    final weekOrder = [
      for (var i = 0; i < 7; i++)
        ((firstDow + i) % 7 == 0 ? 7 : (firstDow + i) % 7),
    ];

    Widget weekdayChips(
      String key,
      bool Function(int) isOn,
      ValueChanged<int> onTap,
    ) => chips([
      for (final d in weekOrder)
        AppChip(
          key: ValueKey('$key$d'),
          label: loc.narrowWeekdays[d % 7],
          tooltip: _weekdayName(l, d),
          selected: isOn(d),
          onTap: () => onTap(d),
        ),
    ]);

    final byDay = widget.simple || _monthlyMode == RecurrenceMonthlyMode.day;
    final moved = !DateUtils.isSameDay(_rule.start, _base);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          recurrenceLabel(l, _rule, showEnd: true),
          role: AppTextRole.title,
          color: scheme.primary,
        ),
        if (moved) ...[
          const SizedBox(height: AppSpacing.xs),
          AppText(
            l.recurSheetStartMoves(
              DateFormat.yMMMd(l.localeName).format(_rule.start),
            ),
            key: const ValueKey('recurStartMoves'),
            role: AppTextRole.caption,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppText(l.recurSheetEvery),
            const SizedBox(width: AppSpacing.sm),
            numberField(_intervalText, 99, (n) => _edit(() => _interval = n)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: chips([
                for (final f in _units)
                  AppChip(
                    label: _unitLabel(l, f),
                    selected: _freq == f,
                    onTap: () => _edit(() => _freq = f),
                  ),
              ]),
            ),
          ],
        ),
        if (_freq == RecurrenceFreq.weekly)
          section(
            widget.simple ? l.recurSheetPeriodStart : l.recurSheetRepeatOn,
            widget.simple
                ? weekdayChips(
                    'recurWeekday',
                    (d) => _startWeekday == d,
                    (d) => _edit(() => _startWeekday = d),
                  )
                : weekdayChips(
                    'recurWeekday',
                    _weekdays.contains,
                    _toggleWeekday,
                  ),
          ),
        if (_freq == RecurrenceFreq.monthly)
          section(
            widget.simple ? l.recurSheetPeriodStart : l.recurSheetMonthlyOn,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.simple) ...[
                  chips([
                    AppChip(
                      key: const ValueKey('recurByDay'),
                      label: l.recurSheetByDay,
                      selected: byDay,
                      onTap: () =>
                          _edit(() => _monthlyMode = RecurrenceMonthlyMode.day),
                    ),
                    AppChip(
                      key: const ValueKey('recurByWeekday'),
                      label: l.recurSheetByWeekday,
                      selected: !byDay,
                      onTap: () => _edit(
                        () => _monthlyMode = RecurrenceMonthlyMode.weekday,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (byDay)
                  DayOfMonthGrid(
                    key: const ValueKey('recurMonthDay'),
                    selected: _monthDay,
                    allowNone: false,
                    padding: EdgeInsets.zero,
                    onPicked: (d) => _edit(() => _monthDay = d ?? _monthDay),
                  )
                else ...[
                  chips([
                    for (final n in const [
                      1,
                      2,
                      3,
                      4,
                      RecurrenceMonthly.lastWeek,
                    ])
                      AppChip(
                        key: ValueKey('recurNth$n'),
                        label: n == RecurrenceMonthly.lastWeek
                            ? strings.dayLastShort
                            : l.recurSheetNth(_ordinal(n), n),
                        selected: _nth == n,
                        onTap: () => _edit(() => _nth = n),
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  weekdayChips(
                    'recurNthWeekday',
                    (d) => _nthWeekday == d,
                    (d) => _edit(() => _nthWeekday = d),
                  ),
                ],
              ],
            ),
          ),
        if (_freq == RecurrenceFreq.yearly)
          section(
            widget.simple ? l.recurSheetPeriodStart : l.recurSheetYearlyOn,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                MonthOfYearGrid(
                  selected: _yearMonth,
                  onPicked: (m) => _edit(() {
                    _yearMonth = m;
                    _yearDay = _yearDay.clamp(1, _daysIn(m));
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                DayOfMonthGrid(
                  key: const ValueKey('recurYearDay'),
                  days: _daysIn(_yearMonth),
                  selected: _yearDay,
                  allowNone: false,
                  padding: EdgeInsets.zero,
                  onPicked: (d) => _edit(() => _yearDay = d ?? _yearDay),
                ),
              ],
            ),
          ),
        section(
          l.recurSheetEnds,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              chips([
                for (final (kind, label) in [
                  (RecurrenceEndKind.never, l.recurSheetEndNever),
                  (RecurrenceEndKind.onDate, l.recurSheetEndOnDate),
                  (RecurrenceEndKind.afterCount, l.recurSheetEndAfter),
                ])
                  AppChip(
                    label: label,
                    selected: _endKind == kind,
                    onTap: () => _edit(() => _endKind = kind),
                  ),
              ]),
              if (_endKind == RecurrenceEndKind.onDate) ...[
                const SizedBox(height: AppSpacing.md),
                AppChip(
                  label: DateFormat.yMMMd(l.localeName).format(_endDate),
                  icon: AppIcons.date,
                  trailing: AppChipTrailing.dropdown,
                  onTap: _pickEndDate,
                ),
              ],
              if (_endKind == RecurrenceEndKind.afterCount) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    numberField(
                      _countText,
                      999,
                      (n) => _edit(() => _endCount = n),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppText(l.recurSheetOccurrences(_endCount)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

String _ordinal(int nth) => switch (nth) {
  1 => 'first',
  2 => 'second',
  3 => 'third',
  4 => 'fourth',
  _ => 'other',
};

String _weekdayName(AppLocalizations l, int isoWeekday) => switch (isoWeekday) {
  1 => l.recurWeekday1,
  2 => l.recurWeekday2,
  3 => l.recurWeekday3,
  4 => l.recurWeekday4,
  5 => l.recurWeekday5,
  6 => l.recurWeekday6,
  _ => l.recurWeekday7,
};
