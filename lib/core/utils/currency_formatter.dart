import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String format(
    num amount, {
    String symbol = '฿',
    String locale = 'en_US',
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String compact(num amount, {String locale = 'en_US'}) {
    return NumberFormat.compact(locale: locale).format(amount);
  }
}
