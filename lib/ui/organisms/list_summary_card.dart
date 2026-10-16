import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_card.dart';
import '../domain/money/money_text.dart';
import '../molecules/hero_style.dart';
import '../molecules/progress_row.dart';
import '../molecules/selectable_frame.dart';
import '../tokens/app/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// The colour family of a [SummaryTile] (income-green, warning-amber, ...).
enum SummaryTileTone { neutral, green, amber, red, orange }

/// One tile of a [ListSummaryCard]: a small label over a bold value, tinted
/// by [tone]. With [onTap] it is a filter; [selected] rings it in primary
/// (tap-again-to-clear is the page's logic).
@immutable
class SummaryTile {
  const SummaryTile({
    required this.label,
    required this.value,
    this.tone = SummaryTileTone.neutral,
    this.selected = false,
    this.onTap,
    this.caption,
  });

  final String label;
  final String value;
  final SummaryTileTone tone;
  final bool selected;
  final VoidCallback? onTap;

  /// A small line under the value.
  final String? caption;
}

/// A full-width primary button at the bottom of a [ListSummaryCard].
@immutable
class SummaryCta {
  const SummaryCta({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// The ONE summary card at the top of a list page (owner 2026-10-17):
///
///   caption                              [actions]  (CardActionButtons, 👁)
///   main number  + small [mainSuffix]
///   [bar]  (ProgressRow: value / marker / tone + left / right captions)
///   [infoLine]
///   [alert]  amber, tappable
///   [tiles]  2-4 equal tiles in ONE row (filters; [SummaryTile.selected] rings)
///   [cta]    big full-width primary button
///
/// Every part is optional. Words come from the caller. [actions] are the
/// standard top-right slot (`CardActionButton`s, the list's
/// `ToolbarToggleButton`); [showMoneyToggle] adds the 👁 before them.
/// [style] tints the card like a hero (default plain).
class ListSummaryCard extends StatelessWidget {
  const ListSummaryCard({
    this.caption,
    this.actions = const [],
    this.showMoneyToggle = true,
    this.main,
    this.amount,
    this.symbol,
    this.mainTone = MoneyTone.plain,
    this.mainSuffix,
    this.bar,
    this.alert,
    this.onAlertTap,
    this.infoLine,
    this.tiles = const [],
    this.cta,
    this.style = const HeroStyle.plain(),
    this.margin = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    super.key,
  }) : assert(main == null || amount == null, 'main OR amount');

  final String? caption;
  final List<Widget> actions;
  final bool showMoneyToggle;

  /// The big number as a widget, or [amount] (+ [symbol], [mainTone]).
  final Widget? main;
  final num? amount;
  final String? symbol;
  final MoneyTone mainTone;

  /// Small text after the big number ("of 19,000").
  final String? mainSuffix;

  /// The progress bar with its captions.
  final ProgressRow? bar;

  /// The amber alert line; tappable with [onAlertTap].
  final String? alert;
  final VoidCallback? onAlertTap;

  /// A free line under the bar.
  final Widget? infoLine;
  final List<SummaryTile> tiles;
  final SummaryCta? cta;
  final HeroStyle style;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hasTop = caption != null || actions.isNotEmpty || showMoneyToggle;
    final big =
        main ??
        (amount == null
            ? null
            : MoneyText(
                amount!,
                symbol: symbol,
                tone: mainTone,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ));
    const gap = SizedBox(height: AppSpacing.md);
    const small = SizedBox(height: AppSpacing.sm);
    final children = <Widget>[
      if (hasTop)
        Row(
          children: [
            Expanded(
              child: caption == null
                  ? const SizedBox.shrink()
                  : Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
            if (showMoneyToggle) const MoneyVisibilityToggle(),
            for (final a in actions) ...[
              const SizedBox(width: AppSpacing.xs),
              a,
            ],
          ],
        ),
      if (big != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(child: big),
            if (mainSuffix != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  mainSuffix!,
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
      if (bar != null) ...[small, bar!],
      if (infoLine != null) ...[small, infoLine!],
      if (alert != null) ...[
        small,
        _AlertLine(text: alert!, onTap: onAlertTap),
      ],
      if (tiles.isNotEmpty) ...[
        gap,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: _Tile(tile: tiles[i])),
              ],
            ],
          ),
        ),
      ],
      if (cta != null) ...[
        gap,
        AppButton(
          label: cta!.label,
          icon: cta!.icon,
          onPressed: cta!.onTap,
          expand: true,
          size: AppButtonSize.large,
        ),
      ],
    ];
    return HeroSurface(
      style: style,
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class _AlertLine extends StatelessWidget {
  const _AlertLine({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<AppColors>()!.warning;
    return Semantics(
      button: onTap != null,
      child: AppCard(
        key: const ValueKey('summaryAlert'),
        style: AppCardStyle.tinted,
        color: color,
        radius: BorderRadius.circular(AppRadius.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 18, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile});

  final SummaryTile tile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final color = switch (tile.tone) {
      SummaryTileTone.neutral => scheme.onSurfaceVariant,
      SummaryTileTone.green => palette.income,
      SummaryTileTone.amber => palette.warning,
      SummaryTileTone.red => palette.expense,
      SummaryTileTone.orange => Colors.deepOrange,
    };
    final valueColor = tile.tone == SummaryTileTone.neutral
        ? scheme.onSurface
        : color;
    return Semantics(
      button: tile.onTap != null,
      selected: tile.selected,
      child: SelectableFrame(
        selected: tile.selected,
        radius: AppRadius.md,
        gap: 2,
        child: AppCard(
          key: ValueKey('summaryTile:${tile.label}'),
          style: AppCardStyle.tinted,
          color: color,
          radius: BorderRadius.circular(AppRadius.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          onTap: tile.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tile.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                tile.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (tile.caption != null)
                Text(
                  tile.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
