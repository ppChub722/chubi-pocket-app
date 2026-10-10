import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_label.dart';
import '../../domain/transaction_type.dart';
import 'tx_hero_card.dart';

/// "฿1,250  อาหาร" — the amount in the type's colour, then the category:
/// what a transaction form's title says once its hero card's amount has
/// scrolled away (the quick create's title row, the detail page's top bar
/// in edit mode via [AppTopBar.titleSlot]). [onTap] → back to the top.
class TxSummaryTitle extends StatelessWidget {
  const TxSummaryTitle({
    required this.type,
    required this.amount,
    this.category,
    this.onTap,
    this.symbol = '฿',
    super.key,
  });

  final TransactionType type;
  final double amount;

  /// Null = amount only (a transfer, an event row).
  final Category? category;
  final VoidCallback? onTap;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final c = category;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          MoneyText(
            amount,
            symbol: symbol,
            hideable: false,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: txTypeColor(context, type),
            ),
          ),
          if (c != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                categoryDisplayName(l, c),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
