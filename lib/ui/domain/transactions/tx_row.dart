import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../atoms/app_chip.dart';
import '../../tokens/chip_size.dart';
import '../money/money_text.dart';

class TxRow extends StatelessWidget {
  const TxRow({
    required this.leading,
    required this.title,
    required this.amount,
    this.tone = MoneyTone.signed,
    this.walletLabel,
    this.walletIcon,
    this.walletFill,
    this.walletGlyph,
    this.walletOnFill,
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

  final String? amountText;
  final MoneyTone tone;

  final String? walletLabel;

  final Widget? walletIcon;

  final Color? walletFill;
  final IconData? walletGlyph;
  final Color? walletOnFill;

  final Widget? source;

  final String? category;

  final String? extra;

  final List<InlineSpan> tags;
  final bool hasSplits;
  final Widget? select;
  final String? warning;
  final Color? warningColor;
  final VoidCallback? onTap;

  final Widget? metaLeading;

  final List<String> meta;

  final bool recurring;

  final String? progress;

  final bool linked;

  final Widget? statusChip;

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
          if (parts.isNotEmpty) TextSpan(text: parts.join(' | ')),
          for (final (i, t) in tags.indexed) ...[
            TextSpan(
              text: i == 0 && parts.isEmpty ? '' : (i == 0 ? ' | ' : ' '),
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
                            leading: walletFill == null ? walletIcon : null,
                            icon: walletFill == null ? null : walletGlyph,
                            fill: walletFill,
                            onFill: walletOnFill,
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
                            if (hasLine2) Text(' | ', style: small),
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
