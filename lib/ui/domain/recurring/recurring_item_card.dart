import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';
import '../icons/icon_display.dart';
import '../icons/icon_type.dart';
import '../tokens/app_icons.dart';
import 'occurrence_chain.dart';

/// One line of a [RecurringItemCard]: "รับคืน ทุกวันที่ 30 · ถัดไป 3/5 ·
/// 30 พ.ย." and its amount. [paidBy] = a คนจ่ายแทน line (a person pays for
/// me): a person glyph instead of ↻.
@immutable
class RecurringLineSummary {
  const RecurringLineSummary({
    required this.text,
    this.amount,
    this.paidBy = false,
  });

  final String text;

  /// A MoneyText, usually.
  final Widget? amount;
  final bool paidBy;
}

/// One recurring item as a card (0.4.3): the counterparty page's and the
/// institution page's รายการประจำ section, one card per item. Title and a
/// side label ("ต้องได้ ฿6,000" in [sideTone]), the plan's n/N chain when
/// it has one, then its lines (↻ when · wallet or คนจ่ายแทน · amount).
/// Tinted in the icon's colour; a tap opens the item.
class RecurringItemCard extends StatelessWidget {
  const RecurringItemCard({
    required this.title,
    this.iconCode,
    this.sideLabel,
    this.sideTone,
    this.chain,
    this.lines = const [],
    this.onTap,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final String title;
  final PpForgeIconCode? iconCode;
  final String? sideLabel;

  /// Null = the muted text colour.
  final Tone? sideTone;

  /// The plan's installments (null / empty = no chain).
  final List<ChainDot>? chain;
  final List<RecurringLineSummary> lines;
  final VoidCallback? onTap;

  /// Space around the card (inside a section: the section's side inset).
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tint = iconCode.tintFor(palette);
    final dots = chain ?? const <ChainDot>[];
    final side = sideLabel;
    final card = PpForgeCard(
      style: PpForgeCardStyle.tinted,
      color: tint,
      onTap: onTap,
      padding: const EdgeInsets.all(PpForgeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (iconCode != null) ...[
                IconDisplay(
                  type: IconType.category,
                  size: 28,
                  iconCode: iconCode,
                ),
                const SizedBox(width: PpForgeSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (side != null) ...[
                const SizedBox(width: PpForgeSpacing.sm),
                Text(
                  side,
                  maxLines: 1,
                  style: text.labelMedium?.copyWith(
                    color: sideTone?.color(context) ?? scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (dots.isNotEmpty) ...[
            const SizedBox(height: PpForgeSpacing.sm),
            OccurrenceChain(dots: dots, color: tint),
          ],
          for (final line in lines) ...[
            const SizedBox(height: PpForgeSpacing.xs),
            RecurringLineSummaryRow(line: line),
          ],
        ],
      ),
    );
    return margin == EdgeInsets.zero
        ? card
        : Padding(padding: margin, child: card);
  }
}

/// One [RecurringLineSummary] on its own: ↻ (or a person for คนจ่ายแทน),
/// the text, the amount at the end.
class RecurringLineSummaryRow extends StatelessWidget {
  const RecurringLineSummaryRow({required this.line, super.key});

  final RecurringLineSummary line;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final amount = line.amount;
    return Row(
      children: [
        Icon(
          line.paidBy ? AppIcons.contact : AppIcons.recurring,
          size: 14,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: PpForgeSpacing.xs),
        Expanded(
          child: Text(
            line.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        if (amount != null) ...[
          const SizedBox(width: PpForgeSpacing.sm),
          DefaultTextStyle.merge(
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            child: amount,
          ),
        ],
      ],
    );
  }
}
