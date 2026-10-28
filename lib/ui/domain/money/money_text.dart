import '../../atoms/amount_text.dart';
import 'package:flutter/material.dart';

import '../../atoms/ui_config.dart';
import '../../tokens/app/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import 'money_style.dart';

enum MoneyTone { plain, income, expense, signed }

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    this.tone = MoneyTone.plain,
    this.style,
    this.symbol,
    this.hideable = true,
    this.textAlign,
    super.key,
  });

  final num amount;
  final MoneyTone tone;
  final TextStyle? style;

  final String? symbol;

  /// No effect since hide amounts was removed (0.4.1-2); drop with its callers.
  final bool hideable;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final symbol = this.symbol ?? UiConfig.stringsOf(context).currencySymbol;
    final palette = Theme.of(context).extension<AppColors>()!;
    final money = MoneyStyleScope.of(context);
    final digits = money.digitsFor(
      amount,
      CurrencyFormatter.decimalsOfSymbol(symbol),
    );
    final (Color? tint, bool? negative) = switch (tone) {
      MoneyTone.plain => (null, null),
      MoneyTone.income => (palette.income, false),
      MoneyTone.expense => (palette.expense, true),
      MoneyTone.signed =>
        CurrencyFormatter.roundsToZero(amount, decimalDigits: digits)
            ? (null, null)
            : amount > 0
            ? (palette.income, false)
            : (palette.expense, true),
    };
    final color = money.colored ? tint : null;
    final magnitude = tone == MoneyTone.plain ? amount : amount.abs();
    final formatted = CurrencyFormatter.format(
      magnitude,
      symbol: symbol,
      decimalDigits: digits,
    );
    final text = negative == null
        ? formatted
        : money.apply(formatted, negative: negative);
    return AmountText(text, color: color, style: style, textAlign: textAlign);
  }
}

String formatMoneyWith(
  MoneyStyle style,
  num amount, {
  required String symbol,
}) => CurrencyFormatter.format(
  amount,
  symbol: symbol,
  decimalDigits: style.digitsFor(
    amount,
    CurrencyFormatter.decimalsOfSymbol(symbol),
  ),
);

String signedMoneyString(
  BuildContext context,
  num amount, {
  required bool negative,
  String? symbol,
}) => MoneyStyleScope.of(
  context,
).apply(_moneyString(context, amount.abs(), symbol), negative: negative);

String moneyString(BuildContext context, num amount, {String? symbol}) =>
    _moneyString(context, amount, symbol);

String _moneyString(BuildContext context, num amount, String? symbolOrNull) {
  final symbol = symbolOrNull ?? UiConfig.stringsOf(context).currencySymbol;
  final digits = MoneyStyleScope.of(
    context,
  ).digitsFor(amount, CurrencyFormatter.decimalsOfSymbol(symbol));
  return CurrencyFormatter.format(
    amount,
    symbol: symbol,
    decimalDigits: digits,
  );
}
