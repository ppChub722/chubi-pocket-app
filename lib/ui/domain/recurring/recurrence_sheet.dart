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
import 'recurrence_choices.dart';
import 'recurrence_rule.dart';
import 'recurrence_text.dart';

/// The app's one repeat / period sheet: ทุก [N] [วัน / สัปดาห์ / เดือน / ปี],
/// then when it falls, then when it ends. [simple] = a period (a budget's or
/// a goal's รอบ): one start day instead of repeat days ("รอบใหม่เริ่มวัน").
/// [showEnd] false drops the สิ้นสุด part (a goal's รอบ ends with the goal).
/// [title] names the field; none = "ทำซ้ำแบบกำหนดเอง". Every page sets a
/// repeat or a period through this.
abstract final class AppRecurrenceSheet {
  static Future<RecurrenceRule?> show(
    BuildContext context, {
    required RecurrenceRule initial,
    bool simple = false,
    bool showEnd = true,
    String? title,
  }) {
    return showAppSheetCustom<RecurrenceRule>(
      context,
      builder: (_) => _RecurrenceSheet(
        initial: initial,
        simple: simple,
        showEnd: showEnd,
        title: title,
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
  });

  final RecurrenceRule initial;
  final bool simple;
  final bool showEnd;
  final String? title;

  @override
  State<_RecurrenceSheet> createState() => _RecurrenceSheetState();
}

class _RecurrenceSheetState extends State<_RecurrenceSheet> {
  late RecurrenceRule _rule = RecurrenceChoices.normalize(widget.initial);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final strings = UiConfig.stringsOf(context);
    return AppSheetScaffold(
      title: widget.title ?? l.recurSheetTitle,
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
          showEnd: widget.showEnd,
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
    super.key,
  });

  final RecurrenceRule initial;

  final bool simple;

  /// False: no สิ้นสุด part (the rule keeps the end it came with).
  final bool showEnd;

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

  DateTime get _start => _rule.start;

  @override
  void initState() {
    super.initState();
    _rule = RecurrenceChoices.normalize(widget.initial);
    _c = RecurrenceChoices(widget.initial, simple: widget.simple);
    _intervalText = TextEditingController(text: '${_c.interval}');
    _countText = TextEditingController(text: '${_c.endCount}');
  }

  @override
  void dispose() {
    _intervalText.dispose();
    _countText.dispose();
    super.dispose();
  }

  void _edit(VoidCallback change) {
    setState(() => _rule = _c.edit(change));
    widget.onChanged(_rule);
  }

  void _toggleWeekday(int d) {
    final r = _c.toggleWeekday(d);
    if (r == null) return;
    setState(() => _rule = r);
    widget.onChanged(_rule);
  }

  Future<void> _pickEndDate() async {
    final start = DateTime(_start.year, _start.month, _start.day);
    final r = await AppDatePicker.show(
      context,
      initial: _c.endDate,
      first: start,
      last: RecurrenceChoices.lastEndOf(_start),
    );
    if (r is AppDatePicked && mounted) {
      final d = r.date;
      _edit(() => _c.endDate = DateTime(d.year, d.month, d.day));
    }
  }

  String _unitLabel(AppLocalizations l, RecurrenceFreq f) => switch (f) {
    RecurrenceFreq.daily => l.recurSheetUnitDay(_c.interval),
    RecurrenceFreq.weekly => l.recurSheetUnitWeek(_c.interval),
    RecurrenceFreq.monthly => l.recurSheetUnitMonth(_c.interval),
    _ => l.recurSheetUnitYear(_c.interval),
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

    final byDay = widget.simple || _c.monthlyMode == RecurrenceMonthlyMode.day;
    final moved = !DateUtils.isSameDay(_rule.start, _c.base);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          recurrenceLabel(l, _rule, showEnd: widget.showEnd),
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
            numberField(_intervalText, 99, (n) => _edit(() => _c.interval = n)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: chips([
                for (final f in _units)
                  AppChip(
                    label: _unitLabel(l, f),
                    selected: _c.freq == f,
                    onTap: () => _edit(() => _c.freq = f),
                  ),
              ]),
            ),
          ],
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
                    _toggleWeekday,
                  ),
          ),
        if (_c.freq == RecurrenceFreq.monthly)
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
                      onTap: () => _edit(
                        () => _c.monthlyMode = RecurrenceMonthlyMode.day,
                      ),
                    ),
                    AppChip(
                      key: const ValueKey('recurByWeekday'),
                      label: l.recurSheetByWeekday,
                      selected: !byDay,
                      onTap: () => _edit(
                        () => _c.monthlyMode = RecurrenceMonthlyMode.weekday,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (byDay)
                  DayOfMonthGrid(
                    key: const ValueKey('recurMonthDay'),
                    selected: _c.monthDay,
                    allowNone: false,
                    padding: EdgeInsets.zero,
                    onPicked: (d) =>
                        _edit(() => _c.monthDay = d ?? _c.monthDay),
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
                        selected: _c.nth == n,
                        onTap: () => _edit(() => _c.nth = n),
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  weekdayChips(
                    'recurNthWeekday',
                    (d) => _c.nthWeekday == d,
                    (d) => _edit(() => _c.nthWeekday = d),
                  ),
                ],
              ],
            ),
          ),
        if (_c.freq == RecurrenceFreq.yearly)
          section(
            widget.simple ? l.recurSheetPeriodStart : l.recurSheetYearlyOn,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: AppSpacing.md),
                DayOfMonthGrid(
                  key: const ValueKey('recurYearDay'),
                  days: RecurrenceChoices.daysIn(_c.yearMonth),
                  selected: _c.yearDay,
                  allowNone: false,
                  padding: EdgeInsets.zero,
                  onPicked: (d) => _edit(() => _c.yearDay = d ?? _c.yearDay),
                ),
              ],
            ),
          ),
        if (widget.showEnd)
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
                      selected: _c.endKind == kind,
                      onTap: () => _edit(() => _c.endKind = kind),
                    ),
                ]),
                if (_c.endKind == RecurrenceEndKind.onDate) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppChip(
                    label: DateFormat.yMMMd(l.localeName).format(_c.endDate),
                    icon: AppIcons.date,
                    trailing: AppChipTrailing.dropdown,
                    onTap: _pickEndDate,
                  ),
                ],
                if (_c.endKind == RecurrenceEndKind.afterCount) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      numberField(
                        _countText,
                        999,
                        (n) => _edit(() => _c.endCount = n),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppText(l.recurSheetOccurrences(_c.endCount)),
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
