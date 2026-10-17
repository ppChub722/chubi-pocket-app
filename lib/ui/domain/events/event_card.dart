import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../molecules/progress_row.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../icons/color_token.dart';
import '../icons/icon_code.dart';
import '../icons/icon_display.dart';
import '../icons/icon_registry.dart';
import '../icons/icon_type.dart';
import '../money/money_text.dart';

class EventTagRef {
  const EventTagRef(this.name, {this.iconCode});

  final String name;
  final IconCode? iconCode;

  /// The tag's one colour: its icon colour (tags never show a bg), else the
  /// entity tint ([IconCodeTint.tintFor]), else primary.
  Color colorOf(AppColors palette) => (iconCode?.iconColors.isNotEmpty ?? false)
      ? resolveColor(iconCode!.iconColors.first, palette)
      : iconCode.tintFor(palette);

  Widget chip(BuildContext context, {VoidCallback? onTap, double? maxWidth}) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return AppChip(
      label: name,
      icon: IconRegistry.get(iconCode?.icon, fallback: AppIcons.tag),
      color: colorOf(palette),
      selected: true,
      onTap: onTap,
      size: ChipSize.mini,
      maxWidth: maxWidth,
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    required this.name,
    this.iconCode,
    this.description,
    this.tags = const [],
    this.statusLabel,
    this.statusTone = AppChipTone.neutral,
    this.statusDot = true,
    this.meta,
    this.progress,
    this.progressLabel,
    this.progressTrailing,
    this.myNet,
    this.symbol = '฿',
    this.dimmed = false,
    this.onTap,
    super.key,
  });

  static const double iconSize = 40;

  final String name;
  final IconCode? iconCode;
  final String? description;
  final List<EventTagRef> tags;
  final String? statusLabel;
  final AppChipTone statusTone;
  final bool statusDot;
  final String? meta;
  final double? progress;
  final String? progressLabel;
  final String? progressTrailing;
  final num? myNet;
  final String symbol;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final small = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final desc = description?.trim() ?? '';
    final hasMeta = (meta?.isNotEmpty ?? false) || myNet != null;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (statusLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AppChip(
                label: statusLabel!,
                tone: statusTone,
                dot: statusDot,
                selected: true,
                size: ChipSize.mini,
              ),
            ],
          ],
        ),
        if (desc.isNotEmpty)
          Text(
            desc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium,
          ),
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [for (final t in tags) t.chip(context, maxWidth: 140)],
            ),
          ),
        if (hasMeta)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    meta ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                ),
                if (myNet != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  MoneyText(
                    myNet!,
                    tone: MoneyTone.signed,
                    symbol: symbol,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (progress != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ProgressRow(
              value: progress!,
              label: progressLabel,
              trailing: progressTrailing,
              height: 6,
            ),
          ),
      ],
    );

    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconDisplay(
                type: IconType.project,
                size: iconSize,
                iconCode: iconCode,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}
