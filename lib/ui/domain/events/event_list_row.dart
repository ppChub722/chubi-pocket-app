import 'package:flutter/material.dart';

import '../../tokens/app/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../icons/icon_code.dart';
import '../icons/icon_display.dart';
import '../icons/icon_type.dart';
import '../money/money_text.dart';

/// One event in the events list (0.4.0 reference §5): a hairline row, not a
/// boxed card.
///
///   (icon)  name                                   +฿8,250
///           10 ต.ค. · ใช้ไป ฿3,589 · ส่วนฉัน ฿3,589   รอรับ
///
/// - [subtitle]: ONE muted line (dates · spent · my share), built by the
///   caller from the BE's numbers.
/// - [amount] + [tone] + [caption]: my position in the event at the right —
///   `MoneyTone.income` + "รอรับ" (green, +), `MoneyTone.expense` + "รอจ่าย"
///   (red, −); a plain `0` with no caption when I'm even.
/// - [dimmed]: the ended / archived look (faded; still opens).
///
/// Every word comes in as a string: the feature supplies the Thai.
class EventListRow extends StatelessWidget {
  const EventListRow({
    required this.name,
    this.iconCode,
    this.subtitle,
    this.amount = 0,
    this.tone = MoneyTone.plain,
    this.caption,
    this.symbol,
    this.dimmed = false,
    this.onTap,
    super.key,
  });

  /// The leading icon's size.
  static const double iconSize = 40;

  final String name;
  final IconCode? iconCode;
  final String? subtitle;
  final num amount;
  final MoneyTone tone;
  final String? caption;
  final String? symbol;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final captionColor = switch (tone) {
      MoneyTone.income => palette.income,
      MoneyTone.expense => palette.expense,
      _ => scheme.onSurfaceVariant,
    };
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            IconDisplay(
              type: IconType.project,
              size: iconSize,
              iconCode: iconCode,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle?.isNotEmpty ?? false)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                MoneyText(
                  amount,
                  tone: tone,
                  symbol: symbol,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (caption?.isNotEmpty ?? false)
                  Text(
                    caption!,
                    maxLines: 1,
                    style: text.labelSmall?.copyWith(color: captionColor),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}
