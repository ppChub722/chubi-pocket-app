import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'package:ppforge_core/ui.dart';
import '../tokens/app_icons.dart';
import '../money/money_text.dart';
import 'recurrence_choices.dart';
import 'recurrence_dates.dart';
import 'recurrence_rule.dart';
import 'recurrence_text.dart';

/// The app's one repeat / period sheet: ทุก [N] [วัน / สัปดาห์ / เดือน / ปี],
/// then when it falls, then when it ends. [simple] = a period (a budget's or
/// a goal's รอบ): one start day instead of repeat days ("รอบใหม่เริ่มวัน").
/// [showEnd] false drops the สิ้นสุด part (a goal's รอบ ends with the goal).
/// [title] names the field; none = "ทำซ้ำ". A repeat (not [simple]) has two
/// modes, either-or: ทำซ้ำเป็นรอบ | เลือกวันเอง (mock แผ่นทำซ้ำ RepeatB1–B5,
/// B3). [amount] = each round's, when known: the end shows the total. Every
/// page sets a repeat or a period through this.
abstract final class AppRecurrenceSheet {
  static Future<RecurrenceRule?> show(
    BuildContext context, {
    required RecurrenceRule initial,
    bool simple = false,
    bool showEnd = true,
    String? title,
    double? amount,
  }) {
    return showPpForgeSheetCustom<RecurrenceRule>(
      context,
      builder: (_) => _RecurrenceSheet(
        initial: initial,
        simple: simple,
        showEnd: showEnd,
        title: title,
        amount: amount,
      ),
    );
  }
}

class _RecurrenceSheet extends StatefulWidget {
  const _RecurrenceSheet({
    required this.initial,
    required this.simple,
    required this.showEnd,
    required this.title,
    this.amount,
  });

  final RecurrenceRule initial;
  final bool simple;
  final bool showEnd;
  final String? title;
  final double? amount;

  @override
  State<_RecurrenceSheet> createState() => _RecurrenceSheetState();
}

class _RecurrenceSheetState extends State<_RecurrenceSheet> {
  late RecurrenceRule _rule = RecurrenceChoices.normalize(widget.initial);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final strings = PpForgeConfig.stringsOf(context);
    return PpForgeSheetScaffold(
      title: widget.title ?? l.recurSheetTitle,
      footer: Row(
        children: [
          Expanded(
            child: PpForgeButton(
              label: strings.cancel,
              kind: ButtonIconKind.cancel,
              variant: PpForgeButtonVariant.outlined,
              size: PpForgeButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: PpForgeSpacing.md),
          Expanded(
            child: PpForgeButton(
              label: l.commonOk,
              kind: ButtonIconKind.confirm,
              size: PpForgeButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(context).pop(_rule),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
        child: RecurrenceEditor(
          initial: widget.initial,
          simple: widget.simple,
          showEnd: widget.showEnd,
          amount: widget.amount,
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
    this.showEnd = true,
    this.amount,
    super.key,
  });

  final RecurrenceRule initial;

  final bool simple;

  /// False: no สิ้นสุด part (the rule keeps the end it came with).
  final bool showEnd;

  /// The amount of each round, when known: the end shows the total.
  final double? amount;

  final ValueChanged<RecurrenceRule> onChanged;

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
  late final RecurrenceChoices _c;
  late final TextEditingController _intervalText;
  late final TextEditingController _countText;
  late DateTime _datesMonth;
  late DateTime _endMonth;

  DateTime get _start => _rule.start;

  @override
  void initState() {
    super.initState();
    _c = RecurrenceChoices(widget.initial, simple: widget.simple);
    _rule = _c.build();
    _intervalText = TextEditingController(text: '${_c.interval}');
    _countText = TextEditingController(text: '${_c.endCount}');
    final first = _c.dates.isEmpty
        ? _c.base
        : (_c.dates.toList()..sort()).first;
    _datesMonth = DateTime(first.year, first.month);
    _endMonth = DateTime(_c.endDate.year, _c.endDate.month);
  }

  @override
  void dispose() {
    _intervalText.dispose();
    _countText.dispose();
    super.dispose();
  }

  void _set(RecurrenceRule? r) {
    if (r == null) return;
    setState(() => _rule = r);
    widget.onChanged(_rule);
  }

  void _edit(VoidCallback change) => _set(_c.edit(change));

  String _unitLabel(AppLocalizations l, RecurrenceFreq f) => switch (f) {
    RecurrenceFreq.daily => l.recurSheetUnitDay(_c.interval),
    RecurrenceFreq.weekly => l.recurSheetUnitWeek(_c.interval),
    RecurrenceFreq.monthly => l.recurSheetUnitMonth(_c.interval),
    _ => l.recurSheetUnitYear(_c.interval),
  };

  /// A day of the month in the app's model (−1 = last) ↔ the grid's cell (31).
  static int _toCell(int d) =>
      d == RecurrenceRule.lastDay ? kLastDayOfMonth : d;
  static int _fromCell(int d) =>
      d == kLastDayOfMonth ? RecurrenceRule.lastDay : d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);
    final short = DateFormat.MMMd(l.localeName);
    final full = DateFormat.yMMMd(l.localeName);

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(top: PpForgeSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PpForgeText(title, role: PpForgeTextRole.caption),
          const SizedBox(height: PpForgeSpacing.sm),
          child,
        ],
      ),
    );

    Widget chips(List<Widget> children) => Wrap(
      spacing: PpForgeSpacing.sm,
      runSpacing: PpForgeSpacing.sm,
      children: children,
    );

    Widget numberField(
      Key key,
      TextEditingController c,
      int max,
      ValueChanged<int> onValue,
    ) => SizedBox(
      width: 48,
      child: PpForgeInput(
        key: key,
        controller: c,
        dense: true,
        type: PpForgeInputType.number,
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
        PpForgeChip(
          key: ValueKey('$key$d'),
          label: loc.narrowWeekdays[d % 7],
          tooltip: _weekdayName(l, d),
          selected: isOn(d),
          onTap: () => onTap(d),
        ),
    ]);

    // the summary: the rule in words, then its next / last rounds
    final ends =
        _rule.end.kind != RecurrenceEndKind.never ||
        _rule.freq == RecurrenceFreq.dates;
    final ahead = recurrenceDates(
      _rule,
      until: DateTime(_start.year + 3, _start.month, _start.day),
      limit: ends ? 0 : 3,
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final next = ahead.where((d) => !d.isBefore(today)).take(3).toList();
    final total = widget.amount == null || !ends
        ? null
        : moneyString(context, widget.amount! * ahead.length);

    final summary = Column(
      key: const ValueKey('recurSummary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PpForgeText(
          _c.pickDates
              ? (ahead.isEmpty
                    ? l.recurCustomDates(0)
                    : l.recurSheetDatesSpan(
                        ahead.length,
                        full.format(ahead.first),
                        full.format(ahead.last),
                      ))
              : recurrenceLabel(l, _rule, showEnd: widget.showEnd),
          role: PpForgeTextRole.title,
          color: scheme.primary,
        ),
        if (!_c.pickDates && ends && ahead.isNotEmpty) ...[
          const SizedBox(height: PpForgeSpacing.xxs),
          PpForgeText(
            '${full.format(ahead.first)} → ${full.format(ahead.last)}',
            role: PpForgeTextRole.caption,
          ),
        ],
        if (!_c.pickDates && next.isNotEmpty) ...[
          const SizedBox(height: PpForgeSpacing.xxs),
          PpForgeText(
            l.recurSheetNext(
              [for (final d in next) short.format(d)].join(', '),
            ),
            key: const ValueKey('recurNext'),
            role: PpForgeTextRole.caption,
          ),
        ],
      ],
    );

    final monthGrid = DayOfMonthGrid(
      key: const ValueKey('recurMonthDays'),
      selectedDays: {for (final d in _c.monthDays) _toCell(d)},
      allowNone: false,
      padding: EdgeInsets.zero,
      onPicked: (d) => d == null ? null : _set(_c.toggleMonthDay(_fromCell(d))),
    );

    final repeat = <Widget>[
      section(
        l.recurSheetEvery,
        Row(
          children: [
            PpForgeText(l.recurSheetEvery),
            const SizedBox(width: PpForgeSpacing.sm),
            numberField(
              const ValueKey('recurInterval'),
              _intervalText,
              99,
              (n) => _edit(() => _c.interval = n),
            ),
            const SizedBox(width: PpForgeSpacing.sm),
            Expanded(
              child: chips([
                for (final f in _units)
                  PpForgeChip(
                    key: ValueKey('recurUnit${f.name}'),
                    label: _unitLabel(l, f),
                    selected: _c.freq == f,
                    onTap: () => _edit(() => _c.freq = f),
                  ),
              ]),
            ),
          ],
        ),
      ),
      if (_c.freq == RecurrenceFreq.weekly)
        section(
          widget.simple ? l.recurSheetPeriodStart : l.recurSheetRepeatOn,
          widget.simple
              ? weekdayChips(
                  'recurWeekday',
                  (d) => _c.startWeekday == d,
                  (d) => _edit(() => _c.startWeekday = d),
                )
              : weekdayChips(
                  'recurWeekday',
                  _c.weekdays.contains,
                  (d) => _set(_c.toggleWeekday(d)),
                ),
        ),
      if (_c.freq == RecurrenceFreq.monthly)
        section(
          widget.simple ? l.recurSheetPeriodStart : l.recurSheetMonthlyOn,
          widget.simple
              ? DayOfMonthGrid(
                  key: const ValueKey('recurMonthDay'),
                  selected: _c.monthDay,
                  allowNone: false,
                  padding: EdgeInsets.zero,
                  onPicked: (d) => _edit(() => _c.monthDay = d ?? _c.monthDay),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    monthGrid,
                    const SizedBox(height: PpForgeSpacing.sm),
                    PpForgeText(
                      l.recurSheetMonthDaysHint,
                      role: PpForgeTextRole.caption,
                    ),
                  ],
                ),
        ),
      if (_c.freq == RecurrenceFreq.yearly)
        section(
          widget.simple ? l.recurSheetPeriodStart : l.recurSheetYearlyOn,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: widget.simple
                ? [
                    MonthOfYearGrid(
                      selected: _c.yearMonth,
                      onPicked: (m) => _edit(() {
                        _c.yearMonth = m;
                        _c.yearDay = _c.yearDay.clamp(
                          1,
                          RecurrenceChoices.daysIn(m),
                        );
                      }),
                    ),
                    const SizedBox(height: PpForgeSpacing.md),
                    DayOfMonthGrid(
                      key: const ValueKey('recurYearDay'),
                      days: RecurrenceChoices.daysIn(_c.yearMonth),
                      selected: _c.yearDay,
                      allowNone: false,
                      padding: EdgeInsets.zero,
                      onPicked: (d) =>
                          _edit(() => _c.yearDay = d ?? _c.yearDay),
                    ),
                  ]
                : [
                    MonthOfYearGrid(
                      key: const ValueKey('recurMonths'),
                      selected: 0,
                      selectedMonths: _c.months,
                      onPicked: (m) => _set(_c.toggleMonth(m)),
                    ),
                    const SizedBox(height: PpForgeSpacing.md),
                    PpForgeText(
                      l.recurSheetMonthlyOn,
                      role: PpForgeTextRole.caption,
                    ),
                    const SizedBox(height: PpForgeSpacing.sm),
                    monthGrid,
                  ],
          ),
        ),
      if (widget.showEnd)
        section(
          l.recurSheetEnds,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedChoice<RecurrenceEndKind>(
                key: const ValueKey('recurEnd'),
                expand: true,
                segments: [
                  ChoiceSegment(RecurrenceEndKind.never, l.recurSheetEndNever),
                  ChoiceSegment(
                    RecurrenceEndKind.onDate,
                    l.recurSheetEndOnDate,
                  ),
                  ChoiceSegment(
                    RecurrenceEndKind.afterCount,
                    l.recurSheetEndAfter,
                  ),
                ],
                selected: _c.endKind,
                onChanged: (k) => _edit(() => _c.endKind = k),
              ),
              if (_c.endKind == RecurrenceEndKind.afterCount) ...[
                const SizedBox(height: PpForgeSpacing.md),
                Row(
                  children: [
                    numberField(
                      const ValueKey('recurCount'),
                      _countText,
                      999,
                      (n) => _edit(() => _c.endCount = n),
                    ),
                    const SizedBox(width: PpForgeSpacing.sm),
                    PpForgeText(l.recurSheetOccurrences(_c.endCount)),
                    const SizedBox(width: PpForgeSpacing.md),
                    if (ahead.isNotEmpty)
                      Expanded(
                        child: PpForgeText(
                          [
                            l.recurSheetLast(full.format(ahead.last)),
                            ?total == null ? null : l.recurSheetTotal(total),
                          ].join(' · '),
                          key: const ValueKey('recurCountEnd'),
                          role: PpForgeTextRole.caption,
                        ),
                      ),
                  ],
                ),
              ],
              if (_c.endKind == RecurrenceEndKind.onDate) ...[
                const SizedBox(height: PpForgeSpacing.sm),
                PpForgeText(
                  [
                    l.recurEndUntil(full.format(_c.endDate)),
                    l.recurSheetUntilCount(ahead.length),
                    ?total == null ? null : l.recurSheetTotal(total),
                  ].join(' · '),
                  key: const ValueKey('recurUntilEnd'),
                  role: PpForgeTextRole.caption,
                ),
                const SizedBox(height: PpForgeSpacing.sm),
                MonthCalendar(
                  key: const ValueKey('recurEndCalendar'),
                  month: _endMonth,
                  onMonthChanged: (m) => setState(() => _endMonth = m),
                  selected: _c.endDate,
                  today: today,
                  onSelect: (d) {
                    final first = DateUtils.dateOnly(_start);
                    final last = RecurrenceChoices.lastEndOf(_start);
                    if (d.isBefore(first) || d.isAfter(last)) return;
                    _edit(() => _c.endDate = DateUtils.dateOnly(d));
                  },
                ),
              ],
            ],
          ),
        ),
    ];

    final picked = _c.dates.toList()..sort();
    final dates = <Widget>[
      const SizedBox(height: PpForgeSpacing.md),
      PpForgeText(l.recurSheetDatesHint, role: PpForgeTextRole.caption),
      const SizedBox(height: PpForgeSpacing.sm),
      MonthCalendar(
        key: const ValueKey('recurDatesCalendar'),
        month: _datesMonth,
        onMonthChanged: (m) => setState(() => _datesMonth = m),
        selectedDays: _c.dates,
        today: today,
        onSelect: (d) => _set(_c.toggleDate(d)),
      ),
      section(
        l.recurSheetPickedDates,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in picked)
              Row(
                key: ValueKey('recurPicked:${d.toIso8601String()}'),
                children: [
                  Expanded(
                    child: PpForgeText(
                      DateFormat.yMMMEd(l.localeName).format(d),
                    ),
                  ),
                  PpForgeIconButton(
                    icon: AppIcons.close,
                    tooltip: l.commonRemove,
                    onPressed: () => _set(_c.toggleDate(d)),
                  ),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: PpForgeSpacing.sm),
      PpForgeText(l.recurSheetDatesNoEnd, role: PpForgeTextRole.caption),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.simple) ...[
          SegmentedChoice<bool>(
            key: const ValueKey('recurMode'),
            expand: true,
            segments: [
              ChoiceSegment(false, l.recurSheetModeRepeat),
              ChoiceSegment(true, l.recurSheetModeDates),
            ],
            selected: _c.pickDates,
            onChanged: (v) => _edit(() => _c.pickDates = v),
          ),
          const SizedBox(height: PpForgeSpacing.md),
        ],
        summary,
        if (_c.pickDates) ...dates else ...repeat,
        const SizedBox(height: PpForgeSpacing.sm),
      ],
    );
  }
}

String _weekdayName(AppLocalizations l, int isoWeekday) => switch (isoWeekday) {
  1 => l.recurWeekday1,
  2 => l.recurWeekday2,
  3 => l.recurWeekday3,
  4 => l.recurWeekday4,
  5 => l.recurWeekday5,
  6 => l.recurWeekday6,
  _ => l.recurWeekday7,
};
