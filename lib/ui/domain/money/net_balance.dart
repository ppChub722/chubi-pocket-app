import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../tokens/app/app_colors.dart';
import 'money_text.dart';

/// The debt-state colour everywhere a debt says who owes whom: รอรับ (they
/// owe me) green, รอจ่าย (I owe) red (owner 2026-10-17). The debts pages, the
/// person hero and the quick-create direction chips (รอรับ / รอจ่าย)
/// all take it from here.
Color debtStateColor(BuildContext context, {required bool owedToMe}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  return owedToMe ? palette.income : palette.expense;
}

enum NetBalanceSize { row, hero }

class NetBalance extends StatelessWidget {
  const NetBalance({
    required this.amount,
    required this.owedToMeLabel,
    required this.iOweLabel,
    required this.settledLabel,
    this.size = NetBalanceSize.row,
    this.currencySymbol,
    this.showCaption = true,
    super.key,
  });

  final bool showCaption;

  final num amount;
  final String owedToMeLabel;
  final String iOweLabel;
  final String settledLabel;
  final NetBalanceSize size;
  final String? currencySymbol;

  bool get isSettled => CurrencyFormatter.roundsToZero(amount);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hero = size == NetBalanceSize.hero;
    final align = hero ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = hero ? TextAlign.start : TextAlign.end;
    final captionStyle = (hero ? textTheme.labelLarge : textTheme.labelSmall)
        ?.copyWith(color: scheme.onSurfaceVariant);

    if (isSettled) {
      return Text(
        settledLabel,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (hero ? textTheme.titleMedium : textTheme.labelMedium)?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final owedToMe = amount > 0;
    final color = debtStateColor(context, owedToMe: owedToMe);
    final amountStyle = (hero ? textTheme.headlineMedium : textTheme.titleSmall)
        ?.copyWith(
          color: color,
          fontWeight: hero ? FontWeight.w800 : FontWeight.w700,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        MoneyText(
          amount.abs(),
          symbol: currencySymbol,
          textAlign: textAlign,
          style: amountStyle,
        ),
        if (showCaption)
          Text(
            owedToMe ? owedToMeLabel : iOweLabel,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: captionStyle,
          ),
      ],
    );
  }
}
