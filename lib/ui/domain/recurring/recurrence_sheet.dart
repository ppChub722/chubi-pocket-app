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
import '../../organisms/app_date_picker.dart';
import '../../organisms/app_sheet.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/typography.dart';
import 'recurrence_rule.dart';
import 'recurrence_text.dart';

/// Opens the "custom repeat" sheet (Google Calendar's "Custom…"): a
/// [RecurrenceEditor] under a title, Cancel · OK pinned at the bottom.
/// Resolves the edited rule on OK, null on Cancel / dismiss.
///
/// [simple]: only "every N day | week | month | year" and the end (budget
/// periods) — see [RecurrenceEditor.simple].
///
/// A [RecurrenceFreq.dates] rule is not edited here — it starts as a
/// monthly rule (hand-picked dates have their own picker,
/// `showMultiDatePicker`).
///
/// ```dart
/// final r = await showRecurrenceSheet(context, initial: rule);
/// if (r != null) setState(() => rule = r);
/// ```
Future<RecurrenceRule?> showRecurrenceSheet(
  BuildContext context, {
  required RecurrenceRule initial,
  bool simple = false,
}) {
  return showPpForgeSheetCustom<RecurrenceRule>(
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
    final strings = PpForgeConfig.stringsOf(context);
    return PpForgeSheetScaffold(
      title: l.recurSheetTitle,
      footer: Row(
        children: [
          Expanded(
            child: PpForgeButton(
              label: strings.cancel,
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
          onChanged: (r) => _rule = r,
        ),
      ),
    );
  }
}

/// The body of [showRecurrenceSheet] — edits a [RecurrenceRule] in place,
/// Google Calendar style, and reports every change through [onChanged]:
///
/// - a live summary on top ([recurrenceLabel] with the end);
/// - "every [N] [day | week | month | year]" — the interval (1..99) and the
///   unit chips;
/// - weekly: the 7 weekday toggles (ISO 1 = Monday .. 7 = Sunday, in the
///   locale's week order), at least one stays on (default = the start
///   date's weekday);
/// - monthly: on day D (31 = the last day of the month) or on the Nth
///   weekday (the start date's; its 5th = the last one);
/// - yearly: the start date's month + day (nothing to pick);
/// - ends: never · on a date (start .. start + 2 years) · after N times
///   (1..999).
///
/// [initial] is read once (give a new key to reset it); a
/// [RecurrenceFreq.dates] rule starts as monthly ([normalize]). The rule's
/// [RecurrenceRule.start] is never changed here.
class RecurrenceEditor extends StatefulWidget {
  const RecurrenceEditor({
    required this.initial,
    required this.onChanged,
    this.simple = false,
    super.key,
  });

  final RecurrenceRule initial;

  /// Only "every N [day|week|month|year]" and the end: no weekday toggles, no
  /// monthly day / Nth-weekday choice (a budget period). The rule it reports
  /// has no weekdays and no monthly part.
  final bool simple;

  /// Every edit, with the whole rule.
  final ValueChanged<RecurrenceRule> onChanged;

  /// The longest end date: this long after the start.
  static const endSpanYears = 2;

  /// The rule the editor starts from: hand-picked dates become monthly, the
  /// interval at least 1.
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
  late RecurrenceFreq _freq;
  late int _interval;
  late Set<int> _weekdays;
  late RecurrenceMonthlyMode _monthlyMode;
  late int _monthDay;
  late int _nth;
  late int _nthWeekday;
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
    _freq = _rule.freq;
    _interval = _rule.interval.clamp(1, 99);
    _weekdays = {
      for (final d in _rule.weekdays)
        if (d >= 1 && d <= 7) d,
    };
    if (_weekdays.isEmpty) _weekdays = {start.weekday};

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

  RecurrenceRule _build() => RecurrenceRule(
    freq: _freq,
    start: _start,
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
    final r = await showPpForgeDatePicker(
      context,
      initial: _endDate,
      first: start,
      last: _lastEnd,
    );
    if (r is PpForgeDatePicked && mounted) {
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
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);

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
      TextEditingController c,
      int max,
      ValueChanged<int> onValue,
    ) => SizedBox(
      width: 72,
      child: PpForgeInput(
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
    final nthName = _weekdayName(l, _nthWeekday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PpForgeText(
          recurrenceLabel(l, _rule, showEnd: true),
          role: PpForgeTextRole.title,
          color: scheme.primary,
        ),
        const SizedBox(height: PpForgeSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PpForgeText(l.recurSheetEvery),
            const SizedBox(width: PpForgeSpacing.sm),
            numberField(_intervalText, 99, (n) => _edit(() => _interval = n)),
            const SizedBox(width: PpForgeSpacing.md),
            Expanded(
              child: chips([
                for (final f in _units)
                  PpForgeChip(
                    label: _unitLabel(l, f),
                    selected: _freq == f,
                    onTap: () => _edit(() => _freq = f),
                  ),
              ]),
            ),
          ],
        ),
        if (_freq == RecurrenceFreq.weekly && !widget.simple)
          section(
            l.recurSheetRepeatOn,
            chips([
              for (final d in weekOrder)
                PpForgeChip(
                  key: ValueKey('recurWeekday$d'),
                  label: loc.narrowWeekdays[d % 7],
                  tooltip: _weekdayName(l, d),
                  selected: _weekdays.contains(d),
                  onTap: () => _toggleWeekday(d),
                ),
            ]),
          ),
        if (_freq == RecurrenceFreq.monthly && !widget.simple)
          section(
            l.recurSheetMonthlyOn,
            chips([
              PpForgeChip(
                label: _monthDay >= RecurrenceMonthly.lastDay
                    ? l.recurSheetLastDayOfMonth
                    : l.recurOnDay(_monthDay),
                selected: _monthlyMode == RecurrenceMonthlyMode.day,
                onTap: () =>
                    _edit(() => _monthlyMode = RecurrenceMonthlyMode.day),
              ),
              PpForgeChip(
                label: _nth == RecurrenceMonthly.lastWeek
                    ? l.recurOnLastWeekday(nthName)
                    : l.recurOnNthWeekday(_ordinal(_nth), _nth, nthName),
                selected: _monthlyMode == RecurrenceMonthlyMode.weekday,
                onTap: () =>
                    _edit(() => _monthlyMode = RecurrenceMonthlyMode.weekday),
              ),
            ]),
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
                  PpForgeChip(
                    label: label,
                    selected: _endKind == kind,
                    onTap: () => _edit(() => _endKind = kind),
                  ),
              ]),
              if (_endKind == RecurrenceEndKind.onDate) ...[
                const SizedBox(height: PpForgeSpacing.md),
                PpForgeChip(
                  label: DateFormat.yMMMd(l.localeName).format(_endDate),
                  icon: PpForgeIcons.date,
                  trailing: PpForgeChipTrailing.dropdown,
                  onTap: _pickEndDate,
                ),
              ],
              if (_endKind == RecurrenceEndKind.afterCount) ...[
                const SizedBox(height: PpForgeSpacing.md),
                Row(
                  children: [
                    numberField(
                      _countText,
                      999,
                      (n) => _edit(() => _endCount = n),
                    ),
                    const SizedBox(width: PpForgeSpacing.sm),
                    PpForgeText(l.recurSheetOccurrences(_endCount)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: PpForgeSpacing.sm),
      ],
    );
  }
}

/// The select key the English ordinal strings switch on (as in
/// [recurrenceLabel]).
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
