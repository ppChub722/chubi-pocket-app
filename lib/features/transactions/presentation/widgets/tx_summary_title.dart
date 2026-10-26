import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_label.dart';
import '../../domain/transaction_type.dart';

class TxSummaryTitle extends StatelessWidget {
  const TxSummaryTitle({
    required this.type,
    required this.amount,
    this.category,
    this.onTap,
    this.symbol,
    super.key,
  });

  final TransactionType type;
  final double amount;

  final Category? category;
  final VoidCallback? onTap;

  /// Null = the user's currency.
  final String? symbol;

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
