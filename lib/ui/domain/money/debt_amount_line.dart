import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../atoms/app_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import 'money_text.dart';

/// The debt person hero's row C (owner 2026-10-17, reference §4): ONE line,
///
///   [รอรับ]  ฿1,189.67
///
/// a pill chip saying the side (green "รอรับ" = they owe me, red "รอจ่าย" = I
/// owe) and the amount (magnitude, coloured by side). A net that shows as
/// zero is the muted [settledLabel] alone — no pill, no colour. Goes into
/// `HeroCard.number`. Words come from the caller.
class DebtAmountLine extends StatelessWidget {
  const DebtAmountLine({
    required this.net,
    required this.owedToMeLabel,
    required this.iOweLabel,
    required this.settledLabel,
    this.currencySymbol = '฿',
    super.key,
  });

  /// The signed net: + = they owe me, − = I owe them.
  final num net;
  final String owedToMeLabel;
  final String iOweLabel;
  final String settledLabel;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
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
    final color = owedToMe ? palette.income : palette.expense;
    return Row(
      children: [
        AppChip(
          label: owedToMe ? owedToMeLabel : iOweLabel,
          tone: owedToMe ? AppChipTone.success : AppChipTone.danger,
          selected: true,
          size: ChipSize.mini,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: MoneyText(
            net.abs(),
            symbol: currencySymbol,
            style: text.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// "ค้าง 45 วัน": the age text of a debt person (hero fact line). [warn]
/// (over 30 days) turns it amber and semibold. Same look as the list row's
/// subtitle.
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

/// The people list card's net line, shown only when both sides are open:
/// "สุทธิ  +฿1,250.00" — the label muted, the signed amount tinted.
class DebtNetLine extends StatelessWidget {
  const DebtNetLine({
    required this.label,
    required this.net,
    this.currencySymbol = '฿',
    super.key,
  });

  final String label;
  final num net;
  final String currencySymbol;

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
