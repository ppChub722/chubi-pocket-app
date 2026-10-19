import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import '../../atoms/app_chip.dart';
import '../../atoms/icon_tile.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import 'money_text.dart';

enum LedgerDirection { paid, received }

class LedgerRow extends StatelessWidget {
  const LedgerRow({
    required this.direction,
    required this.amount,
    required this.title,
    required this.dateLabel,
    this.walletLabel,
    this.walletIcon,
    this.paidLabel,
    this.sourceLabel,
    this.currencySymbol = '฿',
    this.signed = false,
    this.onTap,
    super.key,
  });

  final bool signed;

  final LedgerDirection direction;

  final num amount;
  final String title;
  final String dateLabel;

  final String? walletLabel;

  final Widget? walletIcon;

  final String? paidLabel;

  final String? sourceLabel;
  final String currencySymbol;
  final VoidCallback? onTap;

  static const double leadingSize = 36;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final paid = direction == LedgerDirection.paid;
    final color = paid ? palette.expense : palette.income;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final leading = Transform.rotate(
      angle: paid ? -math.pi / 4 : math.pi * 3 / 4,
      child: IconTile(
        icon: AppIcons.arrowForward,
        color: color,
        size: leadingSize,
      ),
    );

    Widget mini(String label, {Widget? icon, AppChipTone? tone}) => Flexible(
      child: _OnLine(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: AppChip(
            label: label,
            leading: icon,
            tone: tone,
            selected: tone != null,
            size: ChipSize.mini,
          ),
        ),
      ),
    );

    final hasChips = walletLabel != null || paidLabel != null;
    final line2 = Row(
      children: [
        Flexible(
          child: Text(
            dateLabel,
            style: small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasChips) ...[
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (walletLabel != null) mini(walletLabel!, icon: walletIcon),
                if (walletLabel != null && paidLabel != null)
                  const SizedBox(width: AppSpacing.xs),
                if (paidLabel != null)
                  mini(paidLabel!, tone: AppChipTone.success),
              ],
            ),
          ),
        ],
        if (sourceLabel != null && sourceLabel!.isNotEmpty)
          Flexible(
            child: Text(
              ' | ${sourceLabel!}',
              style: small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge,
                  ),
                  Padding(padding: const EdgeInsets.only(top: 2), child: line2),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (signed)
              Text(
                '${paid ? '+' : '−'}'
                '${moneyString(context, amount.abs(), symbol: currencySymbol)}',
                maxLines: 1,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: paid ? scheme.onSurface : palette.income,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            else
              MoneyText(
                amount.abs(),
                symbol: currencySymbol,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnLine extends StatelessWidget {
  const _OnLine({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 0,
    child: OverflowBox(
      minHeight: 0,
      maxHeight: double.infinity,
      fit: OverflowBoxFit.deferToChild,
      child: child,
    ),
  );
}
