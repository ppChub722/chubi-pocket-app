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
}
