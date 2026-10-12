import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../tokens/tone.dart';

/// "วันนี้" / "พรุ่งนี้" / "เมื่อวาน" / "อีก 3 วัน" / "เลยกำหนด 2 วัน",
/// followed by a short localized date when [withDate] ("อีก 3 วัน · 16 ต.ค.";
/// the year is added when it is not this year).
///
/// [daysUntil] = the day distance the BE sends (`days_until`); null = it is
/// computed from [date] against today (local calendar days; [today]
/// overrides "now", for tests). [localeCode] null = the localizations'
/// locale. Pages and other kit pieces use this; [DueText] renders it.
String dueLabel(
  AppLocalizations l, {
  required DateTime date,
  int? daysUntil,
  String? localeCode,
  bool withDate = true,
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final n = daysUntil ?? _daysBetween(now, date);
  final rel = switch (n) {
    0 => l.dueToday,
    1 => l.dueTomorrow,
    -1 => l.dueYesterday,
    > 1 => l.dueInDays(n),
    _ => l.dueOverdueDays(-n),
  };
  if (!withDate) return rel;
  final locale = localeCode ?? l.localeName;
  final short = date.year == now.year
      ? DateFormat.MMMd(locale).format(date)
      : DateFormat.yMMMd(locale).format(date);
  return '$rel · $short';
}

/// Calendar days from [from] to [to] (date parts only, DST-proof).
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// A due date as relative text — [dueLabel] on one ellipsised line. Overdue
/// (before today) is tinted danger when [tintOverdue]; otherwise the muted
/// meta colour. [style] replaces the default `bodySmall` (the tint still
/// applies on top when overdue).
class DueText extends StatelessWidget {
  const DueText({
    required this.date,
    this.daysUntil,
    this.withDate = true,
    this.style,
    this.tintOverdue = true,
    this.today,
    super.key,
  });

  final DateTime date;

  /// The BE's `days_until`; null = computed from today.
  final int? daysUntil;
  final bool withDate;
  final TextStyle? style;
  final bool tintOverdue;

  /// Overrides "now" (tests, hub demos).
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final n = daysUntil ?? _daysBetween(today ?? DateTime.now(), date);
    final overdue = n < 0;
    var s =
        style ??
        Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    if (overdue && tintOverdue) {
      s = (s ?? const TextStyle()).copyWith(color: Tone.danger.color(context));
    }
    return Text(
      dueLabel(l, date: date, daysUntil: n, withDate: withDate, today: today),
      style: s,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
