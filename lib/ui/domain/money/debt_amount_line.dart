import '../../organisms/hero/status_amount_line.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../atoms/app_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import 'money_text.dart';
import 'net_balance.dart';

class DebtAmountLine extends StatelessWidget {
  const DebtAmountLine({
    required this.net,
    required this.owedToMeLabel,
    required this.iOweLabel,
    required this.settledLabel,
    this.currencySymbol,
    super.key,
  });

  final num net;
  final String owedToMeLabel;
  final String iOweLabel;
  final String settledLabel;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (CurrencyFormatter.roundsToZero(net)) {
      return Text(
        settledLabel,
        style: text.headlineSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final owedToMe = net > 0;
    return StatusAmountLine(
      status: owedToMe ? owedToMeLabel : iOweLabel,
      icon: owedToMe ? AppIcons.flowIn : AppIcons.flowOut,
      chipSize: ChipSize.control,
      tone: owedToMe ? AppChipTone.success : AppChipTone.danger,
      color: debtStateColor(context, owedToMe: owedToMe),
      amount: MoneyText(net.abs(), symbol: currencySymbol),
    );
  }
}

class DebtAgeText extends StatelessWidget {
  const DebtAgeText(this.text, {this.warn = false, super.key});

  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: warn
          ? TextStyle(color: palette.warning, fontWeight: FontWeight.w600)
          : null,
    );
  }
}

class DebtNetLine extends StatelessWidget {
  const DebtNetLine({
    required this.label,
    required this.net,
    this.currencySymbol,
    super.key,
  });

  final String label;
  final num net;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: MoneyText(
            net,
            tone: MoneyTone.signed,
            symbol: currencySymbol,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
