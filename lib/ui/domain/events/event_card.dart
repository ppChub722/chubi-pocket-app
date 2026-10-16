import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';
import '../icons/icon_type.dart';
import '../money/money_text.dart';

/// A tag as the events pieces show it: a name and its icon (null = the
/// generic tag glyph in primary). Plain data — the feature maps its own tag
/// (a user tag, an event tag) into it.
class EventTagRef {
  const EventTagRef(this.name, {this.iconCode});

  final String name;
  final IconCode? iconCode;

  /// The tag's one colour: its icon colour (tags never show a bg), else
  /// the entity tint ([IconCodeTint.tintFor]), else primary.
  Color colorOf(PpForgeColors palette) =>
      (iconCode?.iconColors.isNotEmpty ?? false)
      ? resolveColor(iconCode!.iconColors.first, palette)
      : iconCode.tintFor(palette);

  /// The tag as a mini [PpForgeChip] (dense list rows): `[icon] name` in its
  /// colour. [onTap] null = display only.
  Widget chip(BuildContext context, {VoidCallback? onTap, double? maxWidth}) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    return PpForgeChip(
      label: name,
      icon: IconRegistry.get(iconCode?.icon, fallback: PpForgeIcons.tag),
      color: colorOf(palette),
      selected: true,
      onTap: onTap,
      size: ChipSize.mini,
      maxWidth: maxWidth,
    );
  }
}

/// One event in the events list (owner 2026-10-12, replaces the page's
/// private `_ProjectCard`). A hairline-separated row, not a boxed card:
///
///   (icon)  name                                   [● status]
///           description
///           [tag] [tag]
///           meta caption                              +฿120
///           ▓▓▓▓▓▓▓▓░░░░░░  plan label         trailing
///
/// - [iconCode]: the event's icon ([IconDisplay], project fallback).
/// - [statusLabel] / [statusTone] / [statusDot]: the status as a mini chip.
/// - [tags]: the user's own tags on the event, as mini chips.
/// - [meta]: one caption line ("4 คน · 1–5 ต.ค.").
/// - [progress] (ratio, >1 = over plan) + [progressLabel] /
///   [progressTrailing]: the plan bar; null = no plan.
/// - [myNet]: my position, a signed amount (+ = I'm owed); null = hidden.
/// - [dimmed]: the locked / archived look (faded; still opens).
///
/// Every word comes in as a string: the feature supplies the Thai.
class EventCard extends StatelessWidget {
  const EventCard({
    required this.name,
    this.iconCode,
    this.description,
    this.tags = const [],
    this.statusLabel,
    this.statusTone = PpForgeChipTone.neutral,
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

  /// The leading icon's size.
  static const double iconSize = 40;

  final String name;
  final IconCode? iconCode;
  final String? description;
  final List<EventTagRef> tags;
  final String? statusLabel;
  final PpForgeChipTone statusTone;
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
              const SizedBox(width: PpForgeSpacing.sm),
              PpForgeChip(
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
            padding: const EdgeInsets.only(top: PpForgeSpacing.xs),
            child: Wrap(
              spacing: PpForgeSpacing.xs,
              runSpacing: PpForgeSpacing.xs,
              children: [for (final t in tags) t.chip(context, maxWidth: 140)],
            ),
          ),
        if (hasMeta)
          Padding(
            padding: const EdgeInsets.only(top: PpForgeSpacing.xxs),
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
                  const SizedBox(width: PpForgeSpacing.sm),
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
            padding: const EdgeInsets.only(top: PpForgeSpacing.sm),
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
            horizontal: PpForgeSpacing.lg,
            vertical: PpForgeSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconDisplay(
                type: IconType.project,
                size: iconSize,
                iconCode: iconCode,
              ),
              const SizedBox(width: PpForgeSpacing.md),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: row) : row;
  }
}
