import '../../../ui/ui.dart';

/// The API's `rule` + `start_date` + `end` (openapi `RecurrenceRule` /
/// `RecurrenceEnd`) ⇄ the kit's [RecurrenceRule].
RecurrenceRule recurrenceFromJson(
  Map<String, dynamic>? rule, {
  required String? start,
  Map<String, dynamic>? end,
}) {
  final monthly = rule?['monthly'] as Map<String, dynamic>?;
  return RecurrenceRule(
    freq: RecurrenceFreq.values.firstWhere(
      (f) => f.name == rule?['freq'],
      orElse: () => RecurrenceFreq.monthly,
    ),
    start: parseYmd(start) ?? today(),
    interval: (rule?['interval'] as num?)?.toInt() ?? 1,
    weekdays: {
      for (final d in (rule?['weekdays'] as List?) ?? const [])
        (d as num).toInt(),
    },
    monthly: monthly == null
        ? null
        : RecurrenceMonthly(
            mode: monthly['mode'] == 'weekday'
                ? RecurrenceMonthlyMode.weekday
                : RecurrenceMonthlyMode.day,
            day: (monthly['day'] as num?)?.toInt(),
            nth: (monthly['nth'] as num?)?.toInt(),
            weekday: (monthly['weekday'] as num?)?.toInt(),
          ),
    dates: [
      for (final d in (rule?['dates'] as List?) ?? const [])
        ?parseYmd(d as String?),
    ],
    end: switch (end?['kind']) {
      'date' when parseYmd(end?['date'] as String?) != null =>
        RecurrenceEnd.onDate(parseYmd(end?['date'] as String?)!),
      'count' when end?['count'] is num => RecurrenceEnd.afterCount(
        (end!['count'] as num).toInt(),
      ),
      _ => const RecurrenceEnd.never(),
    },
  );
}

/// The `rule`, `start_date` and `end` keys of a write body.
Map<String, dynamic> recurrenceToJson(RecurrenceRule r) {
  final m = r.monthly;
  return <String, dynamic>{
    'rule': <String, dynamic>{
      'freq': r.freq.name,
      'interval': r.interval,
      'weekdays': (r.weekdays.toList()..sort()),
      'monthly': m == null
          ? null
          : <String, dynamic>{
              'mode': m.mode.name,
              'day': m.day,
              'nth': m.nth,
              'weekday': m.weekday,
            },
      'dates': [for (final d in r.dates) ymd(d)],
    },
    'start_date': ymd(r.start),
    'end': <String, dynamic>{
      'kind': switch (r.end.kind) {
        RecurrenceEndKind.never => 'none',
        RecurrenceEndKind.onDate => 'date',
        RecurrenceEndKind.afterCount => 'count',
      },
      if (r.end.kind == RecurrenceEndKind.onDate && r.end.date != null)
        'date': ymd(r.end.date!),
      if (r.end.kind == RecurrenceEndKind.afterCount) 'count': r.end.count,
    },
  };
}

/// Today as a date (no time).
DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// `YYYY-MM-DD` → a local date (null when absent or malformed).
DateTime? parseYmd(String? v) {
  if (v == null || v.isEmpty) return null;
  final d = DateTime.tryParse(v);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

/// A date → `YYYY-MM-DD`.
String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
