import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String short(DateTime date, {String locale = 'en_US'}) =>
      DateFormat.yMd(locale).format(date);

  static String medium(DateTime date, {String locale = 'en_US'}) =>
      DateFormat.yMMMd(locale).format(date);

  static String long(DateTime date, {String locale = 'en_US'}) =>
      DateFormat.yMMMMd(locale).format(date);

  static String monthYear(DateTime date, {String locale = 'en_US'}) =>
      DateFormat.yMMMM(locale).format(date);

  static String time(DateTime date, {String locale = 'en_US'}) =>
      DateFormat.jm(locale).format(date);

  /// Human date for lists and headers: [today] / [yesterday] labels, then
  /// "17 ก.ย." within the current year, "17 ก.ย. 2025" otherwise.
  /// Pass localized labels (`l.commonToday`, `l.commonYesterday`).
  static String friendly(
    DateTime date, {
    required String today,
    required String yesterday,
    String locale = 'th',
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(n.year, n.month, n.day);
    final diff = t.difference(d).inDays;
    if (diff == 0) return today;
    if (diff == 1) return yesterday;
    return d.year == t.year
        ? DateFormat.MMMd(locale).format(d)
        : DateFormat.yMMMd(locale).format(d);
  }

  /// Parses an API `YYYY-MM-DD` date string; null when malformed.
  static DateTime? parseDay(String? ymd) =>
      ymd == null ? null : DateTime.tryParse(ymd);
}
