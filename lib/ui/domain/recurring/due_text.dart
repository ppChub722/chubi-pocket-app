import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../tokens/tone.dart';

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

int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

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

  final int? daysUntil;
  final bool withDate;
  final TextStyle? style;
  final bool tintOverdue;

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
