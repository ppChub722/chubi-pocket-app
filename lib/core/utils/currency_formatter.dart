import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  /// Rounded here first (half away from zero, at [decimalDigits]), so what
  /// shows as zero (−0.0, −0.004, …) prints as a plain zero — never
  /// "-฿0.00" (owner 2026-10-11) — whatever rounding the formatter uses.
  static String format(
    num amount, {
    String symbol = '฿',
    String locale = 'en_US',
    int? decimalDigits,
  }) {
    decimalDigits ??= decimalsOfSymbol(symbol);
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    final scale = _scale(decimalDigits);
    final units = (amount * scale).round();
    return formatter.format(units == 0 ? 0 : units / scale);
  }

  /// True when [amount] shows as zero at [decimalDigits] — a sign or a
  /// +/− colour on it would be noise.
  static bool roundsToZero(
    num amount, {
    String symbol = '฿',
    int? decimalDigits,
  }) =>
      (amount * _scale(decimalDigits ?? decimalsOfSymbol(symbol))).round() == 0;

  /// Minor-unit digits by symbol (JPY ¥ = 0, others 2), so every caller that
  /// already passes the symbol gets the right decimals.
  static int decimalsOfSymbol(String symbol) => symbol == '¥' ? 0 : 2;

  /// Same, by currency code.
  static int decimalsOf(String code) => code == 'JPY' ? 0 : 2;

  static int _scale(int decimalDigits) {
    var scale = 1;
    for (var i = 0; i < decimalDigits; i++) {
      scale *= 10;
    }
    return scale;
  }

  static String compact(num amount, {String locale = 'en_US'}) {
    return NumberFormat.compact(locale: locale).format(amount);
  }
}
