import '../atoms/app_card.dart';
import 'hero/app_hero_card.dart';
import 'hero/summary_tile.dart';
import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../domain/money/money_text.dart';
import '../molecules/hero_style.dart';
import '../molecules/progress_row.dart';
import '../tokens/app/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

class ListSummaryCard extends StatelessWidget {
  const ListSummaryCard({
    this.caption,
    this.captionWidget,
    this.actions = const [],
    this.showMoneyToggle = true,
    this.main,
    this.amount,
    this.symbol,
    this.mainTone = MoneyTone.plain,
    this.mainSuffix,
    this.mainLabel,
    this.bar,
    this.chart,
    this.alert,
    this.onAlertTap,
    this.infoLine,
    this.onInfoTap,
    this.tiles = const [],
    this.cta,
    this.expanded,
    this.style = const HeroStyle.plain(),
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    this.margin = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    super.key,
  }) : assert(main == null || amount == null, 'main OR amount');

  final String? caption;

  final Widget? captionWidget;
  final List<Widget> actions;
  final bool showMoneyToggle;

  final Widget? main;
  final num? amount;
  final String? symbol;
  final MoneyTone mainTone;

  final String? mainSuffix;

  final String? mainLabel;

  final ProgressRow? bar;

  final Widget? chart;

  final String? alert;
  final VoidCallback? onAlertTap;

  final Widget? infoLine;

  final VoidCallback? onInfoTap;
  final List<SummaryTile> tiles;
  final SummaryCta? cta;

  final ValueNotifier<bool>? expanded;
  final HeroStyle style;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final fold = expanded;
    return AppHeroCard(
      style: style,
      margin: margin,
      padding: padding,
      content: [_body(context, true)],
      folded: fold == null ? null : [_body(context, false)],
      open: fold,
    );
  }

  Widget _mainLabel(BuildContext context) => Text(
    mainLabel!,
    maxLines: 1,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _labelled(BuildContext context, Widget? number) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        _mainLabel(context),
        const SizedBox(width: AppSpacing.sm),
        if (number != null) Flexible(child: number),
      ],
    ),
  );

  Widget _body(BuildContext context, bool open) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hasTop =
        caption != null ||
        captionWidget != null ||
        actions.isNotEmpty ||
        showMoneyToggle ||
        expanded != null;
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
    final topRow = hasTop
        ? Row(
            children: [
              Expanded(
                child: captionWidget != null
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: captionWidget,
                      )
                    : caption == null
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
              // The fold sits in the same spot folded or open, so a second tap
              // never has to chase it.
              if (expanded != null) ...[
                const SizedBox(width: AppSpacing.xs),
                const AppHeroFoldButton(key: ValueKey('summaryFold')),
              ],
            ],
          )
        : null;
    if (expanded != null && !open) {
      final number =
          main ??
          (amount == null
              ? null
              : MoneyText(
                  amount!,
                  symbol: symbol,
                  tone: mainTone,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ?topRow,
          if (topRow != null) const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (mainLabel != null)
                _labelled(context, number)
              else if (number != null)
                Flexible(child: number),
            ],
          ),
        ],
      );
    }
    const gap = SizedBox(height: AppSpacing.md);
    const small = SizedBox(height: AppSpacing.sm);
    final children = <Widget>[
      ?topRow,
      if (topRow != null && big != null) const SizedBox(height: AppSpacing.xs),
      if (big != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (mainLabel != null)
              _labelled(context, big)
            else
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
      if (open && chart != null) ...[small, chart!],
      if (open && bar != null) ...[small, bar!],
      if (open && infoLine != null) ...[
        small,
        onInfoTap == null
            ? infoLine!
            : InkWell(onTap: onInfoTap, child: infoLine!),
      ],
      if (open && alert != null) ...[
        small,
        _AlertLine(text: alert!, onTap: onAlertTap),
      ],
      if (open && tiles.isNotEmpty) ...[
        gap,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: SummaryTileView(tile: tiles[i])),
              ],
            ],
          ),
        ),
      ],
      if (open && cta != null) ...[
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
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
