import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../atoms/app_chip.dart';
import '../../tokens/chip_size.dart';
import '../money/money_list_tile.dart';
import '../money/money_text.dart';

/// The ONE row of the transaction list and the pending list (owner
/// 2026-10-11) — two lines, an amount on the right:
///
///   [☐] (icon)  title [wallet chip]                      −฿540
///               [source chip] · category · #tags  ⑂
///
/// - Line 1: the title (description ?? category) and the wallet as a mini
///   [AppChip] with the wallet's icon right after it; the amount at the end.
/// - Line 2: the pending [source] as a mini chip (pending only), then
///   [category], [extra] (a date, "→ wallet") and the [tags] (coloured
///   `#name` spans), one ellipsised line; ⑂ when it has splits.
/// - [select] (a `SelectCheck`) leads the row in the pending list; [warning]
///   adds a line under line 2 (why a draft can't be submitted yet).
///
/// Domain-agnostic: callers resolve names, icons and colours. Dates live in
/// the list's day-group headers ([DateGroupHeader]), not on the row.
class TxRow extends StatelessWidget {
  const TxRow({
    required this.leading,
    required this.title,
    required this.amount,
    this.tone = MoneyTone.signed,
    this.walletLabel,
    this.walletIcon,
    this.source,
    this.category,
    this.extra,
    this.tags = const [],
    this.hasSplits = false,
    this.select,
    this.warning,
    this.warningColor,
    this.onTap,
    super.key,
  });

  final Widget leading;
  final String title;
  final num amount;
  final MoneyTone tone;

  /// The wallet's name — null = no wallet chip (the page is one wallet's).
  final String? walletLabel;

  /// The wallet's icon, shown inside the chip.
  final Widget? walletIcon;

  /// The pending source chip (a mini [AppChip]) — null on transactions.
  final Widget? source;

  final String? category;

  /// Other context on line 2 (a date, "→ wallet").
  final String? extra;

  /// Coloured `#name` spans.
  final List<InlineSpan> tags;
  final bool hasSplits;
  final Widget? select;
  final String? warning;
  final Color? warningColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final parts = [
      if (category != null && category!.isNotEmpty) category!,
      if (extra != null && extra!.isNotEmpty) extra!,
    ];
    final line2 = Text.rich(
      TextSpan(
        children: [
          if (parts.isNotEmpty) TextSpan(text: parts.join(' · ')),
          for (final (i, t) in tags.indexed) ...[
            TextSpan(
              text: i == 0 && parts.isEmpty ? '' : (i == 0 ? ' · ' : ' '),
            ),
            t,
          ],
        ],
      ),
      style: small,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final hasLine2 = parts.isNotEmpty || tags.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (select != null) ...[
              select!,
              const SizedBox(width: AppSpacing.sm),
            ],
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      if (walletLabel != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: AppChip(
                            label: walletLabel!,
                            leading: walletIcon,
                            size: ChipSize.mini,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (source != null || hasLine2 || hasSplits)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (source != null) ...[
                            source!,
                            if (hasLine2) const SizedBox(width: AppSpacing.xs),
                          ],
                          if (hasLine2) Flexible(child: line2),
                          if (hasSplits) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              AppIcons.split,
                              size: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (warning != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.warning,
                            size: 14,
                            color: warningColor ?? scheme.error,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              warning!,
                              style: textTheme.labelSmall?.copyWith(
                                color: warningColor ?? scheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MoneyText(
              amount,
              tone: tone,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
