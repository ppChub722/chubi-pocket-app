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
///   [☐] (icon)  title [wallet chip] [status chip]         −฿540
///               [source chip] [metaLeading] · category · meta · #tags  🔁 3/12 🔗 ⑂
///
/// - Line 1: the title (description ?? category) and the wallet as a mini
///   [AppChip] with the wallet's icon right after it; then the optional
///   [statusChip] (a mini chip, e.g. "หยุดชั่วคราว"); the amount at the end.
///   The status chip rides on line 1 because a mini chip (20) is taller than
///   the line-2 text: there it would grow the row.
/// - Line 2: the pending [source] as a mini chip (pending only), then
///   [metaLeading] (a widget that keeps its own colour, e.g. a `DueText`),
///   [category], [extra] (a date, "→ wallet"), the [meta] texts and the
///   [tags] (coloured `#name` spans), one ellipsised line; then the trailing
///   glyphs: 🔁 + [progress] when [recurring], 🔗 when [linked], ⑂ when it
///   has splits.
/// - [select] (a `SelectCheck`) leads the row in the pending list; [warning]
///   adds a line under line 2 (why a draft can't be submitted yet).
/// - [dimmed] fades the whole row (archived), like `ListRow.dimmed`.
///
/// None of the markers changes the row height (geometry-tested).
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
    this.metaLeading,
    this.meta = const [],
    this.recurring = false,
    this.progress,
    this.linked = false,
    this.statusChip,
    this.dimmed = false,
    this.amountText,
    super.key,
  });

  final Widget leading;
  final String title;
  final num amount;

  /// Words in place of the amount ("รอยอด": no amount yet), muted.
  final String? amountText;
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

  /// Leads line 2 (after [source]) and keeps its own style — e.g. a
  /// `DueText` whose overdue tint must survive.
  final Widget? metaLeading;

  /// More line-2 texts, after [category] / [extra] ("ทุกวันที่ 3").
  final List<String> meta;

  /// 🔁 — made by a recurring item.
  final bool recurring;

  /// Shown right after the 🔁 glyph ("3/12"); needs [recurring].
  final String? progress;

  /// 🔗 — linked to another record (the glyph `EventBillRow` uses).
  final bool linked;

  /// A mini status chip on line 1, after the wallet chip (only when not the
  /// normal state, e.g. paused / archived).
  final Widget? statusChip;

  /// Fades the row (archived).
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final parts = [
      if (category != null && category!.isNotEmpty) category!,
      if (extra != null && extra!.isNotEmpty) extra!,
      for (final m in meta)
        if (m.isNotEmpty) m,
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

    Widget glyph(IconData icon) =>
        Icon(icon, size: 12, color: scheme.onSurfaceVariant);
    final glyphs = <Widget>[
      if (recurring) ...[
        const SizedBox(width: AppSpacing.sm),
        glyph(AppIcons.recurring),
        if (progress != null && progress!.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(progress!, style: small, maxLines: 1),
        ],
      ],
      if (linked) ...[
        const SizedBox(width: AppSpacing.sm),
        glyph(AppIcons.link),
      ],
      if (hasSplits) ...[
        const SizedBox(width: AppSpacing.sm),
        glyph(AppIcons.split),
      ],
    ];
    final showLine2 =
        source != null || metaLeading != null || hasLine2 || glyphs.isNotEmpty;

    final Widget row = InkWell(
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
                      if (statusChip != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(child: statusChip!),
                      ],
                    ],
                  ),
                  if (showLine2)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (source != null) ...[
                            source!,
                            if (hasLine2 || metaLeading != null)
                              const SizedBox(width: AppSpacing.xs),
                          ],
                          if (metaLeading != null) ...[
                            Flexible(child: metaLeading!),
                            if (hasLine2) Text(' · ', style: small),
                          ],
                          if (hasLine2) Flexible(child: line2),
                          ...glyphs,
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
            if (amountText != null)
              Text(
                amountText!,
                style: textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
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
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}
