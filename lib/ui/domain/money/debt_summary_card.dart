import 'package:flutter/material.dart';

import '../../atoms/app_card.dart';
import '../../molecules/selectable_frame.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import 'money_text.dart';

/// The debts people list's summary (owner 2026-10-12, debts rework):
///
///   ┌──────────────────────────────────────────┐
///   │ net label                             👁 │
///   │ +฿1,250.00                               │
///   │ ┌ ติดคุณ ──────────┐ ┌ คุณติด ──────────┐ │
///   │ │ ฿3,000.00         │ │ ฿1,750.00         │ │
///   │ └───────────────────┘ └───────────────────┘ │
///   └──────────────────────────────────────────┘
///
/// - the headline: [net] signed and tinted (income > 0, expense < 0, plain
///   at 0) under [netLabel], with the 👁 [MoneyVisibilityToggle] top right.
/// - two boxes side by side: [owedToMe] (income tint) and [iOwe] (expense
///   tint), each with its label. A box with a tap callback filters the list;
///   [owedToMeSelected] / [iOweSelected] ring the active one.
///
/// Every word comes from the caller (l10n). Amounts come from the BE.
class DebtSummaryCard extends StatelessWidget {
  const DebtSummaryCard({
    required this.owedToMe,
    required this.iOwe,
    required this.netLabel,
    required this.owedToMeLabel,
    required this.iOweLabel,
    this.net,
    this.owedToMeSelected = false,
    this.iOweSelected = false,
    this.onOwedToMeTap,
    this.onIOweTap,
    this.currencySymbol = '฿',
    this.margin = EdgeInsets.zero,
    super.key,
  });

  /// What they owe me in total (shown as its magnitude).
  final num owedToMe;

  /// What I owe in total (shown as its magnitude).
  final num iOwe;

  /// The signed net — null = [owedToMe] − [iOwe].
  final num? net;
  final String netLabel;
  final String owedToMeLabel;
  final String iOweLabel;
  final bool owedToMeSelected;
  final bool iOweSelected;
  final VoidCallback? onOwedToMeTap;
  final VoidCallback? onIOweTap;
  final String currencySymbol;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    return PpForgeCard(
      margin: margin,
      padding: const EdgeInsets.all(PpForgeSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  netLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const MoneyVisibilityToggle(),
            ],
          ),
          MoneyText(
            net ?? owedToMe.abs() - iOwe.abs(),
            symbol: currencySymbol,
            tone: MoneyTone.signed,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: PpForgeSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Box(
                  label: owedToMeLabel,
                  amount: owedToMe,
                  color: palette.income,
                  symbol: currencySymbol,
                  selected: owedToMeSelected,
                  onTap: onOwedToMeTap,
                ),
              ),
              const SizedBox(width: PpForgeSpacing.sm),
              Expanded(
                child: _Box(
                  label: iOweLabel,
                  amount: iOwe,
                  color: palette.expense,
                  symbol: currencySymbol,
                  selected: iOweSelected,
                  onTap: onIOweTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One tinted total box: the label over the amount, ringed when selected.
class _Box extends StatelessWidget {
  const _Box({
    required this.label,
    required this.amount,
    required this.color,
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final num amount;
  final Color color;
  final String symbol;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: SelectableFrame(
        selected: selected,
        color: color,
        radius: PpForgeRadius.md,
        child: PpForgeCard(
          style: PpForgeCardStyle.tinted,
          color: color,
          radius: BorderRadius.circular(PpForgeRadius.md),
          padding: const EdgeInsets.all(PpForgeSpacing.md),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: PpForgeSpacing.xs),
              MoneyText(
                amount.abs(),
                symbol: symbol,
                style: textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
