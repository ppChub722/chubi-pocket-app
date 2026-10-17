import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../tokens/app/app_colors.dart';
import 'money_text.dart';

/// Where a [NetBalance] sits — it sets the text sizes and the alignment.
enum NetBalanceSize {
  /// The trailing end of a list row: the amount over the caption, both
  /// right-aligned, small.
  row,

  /// A hero card's footer: a large amount over the caption, left-aligned.
  hero,
}

/// A person's net with me, as one number + what it means (owner
/// 2026-10-12, debts rework):
///
/// - [amount] > 0 → they owe me: the amount in the income colour +
///   [owedToMeLabel] ("ติดคุณ").
/// - [amount] < 0 → I owe them: the amount shown POSITIVE in the expense
///   colour + [iOweLabel] ("คุณติด").
/// - 0 (anything that shows as 0.00) → only [settledLabel] ("หายกัน"),
///   muted, no amount.
///
/// No sign is drawn: the caption says the direction. The captions come from
/// the caller (l10n).
class NetBalance extends StatelessWidget {
  const NetBalance({
    required this.amount,
    required this.owedToMeLabel,
    required this.iOweLabel,
    required this.settledLabel,
    this.size = NetBalanceSize.row,
    this.currencySymbol = '฿',
    this.showCaption = true,
    super.key,
  });

  /// false: the amount alone (its colour says the side) — the people list.
  final bool showCaption;

  /// The signed net: + = they owe me, − = I owe them.
  final num amount;
  final String owedToMeLabel;
  final String iOweLabel;
  final String settledLabel;
  final NetBalanceSize size;
  final String currencySymbol;

  /// True when [amount] shows as zero (settled).
  bool get isSettled => CurrencyFormatter.roundsToZero(amount);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
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
    final color = owedToMe ? palette.income : palette.expense;
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
