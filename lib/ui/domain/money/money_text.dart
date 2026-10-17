import '../../atoms/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../atoms/ui_config.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/preferences/presentation/cubit/money_visibility_cubit.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'money_style.dart';

enum MoneyTone {
  plain,

  income,

  expense,

  signed,
}

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
  final bool hideable;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final symbol = this.symbol ?? UiConfig.stringsOf(context).currencySymbol;
    final hidden = hideable && isMoneyHidden(context);
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
    final text = hidden
        ? '$symbol••••'
        : negative == null
        ? formatted
        : money.apply(formatted, negative: negative);
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(
        color: color ?? base.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
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
  if (isMoneyHidden(context)) return '$symbol••••';
  final digits = MoneyStyleScope.of(
    context,
  ).digitsFor(amount, CurrencyFormatter.decimalsOfSymbol(symbol));
  return CurrencyFormatter.format(
    amount,
    symbol: symbol,
    decimalDigits: digits,
  );
}

const bool kMoneyPrivacyEnabled = false;

bool isMoneyHidden(BuildContext context) {
  if (!kMoneyPrivacyEnabled) return false;
  try {
    return context.watch<MoneyVisibilityCubit>().state;
  } on ProviderNotFoundException {
    return false;
  }
}

class MoneyVisibilityToggle extends StatelessWidget {
  const MoneyVisibilityToggle({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    if (!kMoneyPrivacyEnabled) return const SizedBox.shrink();
    final hidden = isMoneyHidden(context);
    final l = AppLocalizations.of(context)!;
    return AppIconButton.flat(
      tooltip: hidden ? l.commonShowAmounts : l.commonHideAmounts,
      iconSize: size,
      dense: true,
      icon: hidden ? AppIcons.hidden : AppIcons.visible,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: () => context.read<MoneyVisibilityCubit>().toggle(),
    );
  }
}
