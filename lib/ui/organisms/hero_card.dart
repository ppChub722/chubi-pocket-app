import 'package:flutter/material.dart';

import '../atoms/app_input.dart';
import 'app_hero_card.dart';
import '../atoms/app_input_type.dart';
import '../atoms/ui_config.dart';
import '../molecules/card_action_button.dart';
import '../molecules/hero_shell.dart';
import '../molecules/hero_style.dart';
import '../molecules/progress_row.dart';
import '../tokens/app/app_colors.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.style,
    this.editing = false,
    this.chips = const [],
    this.links = const [],
    this.search,
    this.onEdit,
    this.icon,
    this.name,
    this.fact,
    this.description,
    this.number,
    this.amountField,
    this.bar,
    this.tiles = const [],
    this.alert,
    this.embedded,
    this.settingsLine,
    this.topNote,
    this.middle = const [],
    this.footer,
    this.actionsWhileEditing = false,
    this.padding = const EdgeInsets.all(HeroSpacing.padding),
    this.onTap,
    super.key,
  });

  final HeroStyle style;

  final bool editing;

  final List<Widget> chips;

  final List<Widget> links;

  final Widget? search;

  final VoidCallback? onEdit;

  final Widget? icon;

  final Widget? name;
  final Widget? fact;

  final Widget? description;

  final Widget? number;

  final Widget? amountField;

  final Widget? bar;

  final List<Widget> tiles;

  final Widget? alert;

  final Widget? embedded;

  final Widget? settingsLine;

  final Widget? topNote;

  final List<Widget?> middle;

  final Widget? footer;

  final bool actionsWhileEditing;

  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final edit = !editing && onEdit != null
        ? CardActionButton(
            icon: AppIcons.edit,
            tooltip: UiConfig.stringsOf(context).edit,
            onTap: onEdit,
          )
        : null;
    final actions = editing && !actionsWhileEditing
        ? const <Widget>[]
        : <Widget>[...links, ?search, ?edit];
    final topRow = chips.isNotEmpty || actions.isNotEmpty
        ? HeroTopRow(leading: chips, trailing: actions)
        : null;

    final hasText = name != null || fact != null || description != null;
    final identity = icon == null && !hasText
        ? null
        : Row(
            crossAxisAlignment: editing
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              ?icon,
              if (icon != null && hasText) const SizedBox(width: AppSpacing.md),
              if (hasText)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (name != null)
                        DefaultTextStyle.merge(
                          style: Theme.of(context).textTheme.titleMedium,
                          child: name!,
                        ),
                      if (fact != null)
                        DefaultTextStyle.merge(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          child: fact!,
                        ),
                      if (description != null) ...[
                        if (name != null || fact != null)
                          const SizedBox(height: 2),
                        description!,
                      ],
                    ],
                  ),
                ),
            ],
          );

    final rows = <Widget?>[
      topRow,
      topNote,
      identity,
      ...middle,
      if (editing) amountField else number,
      if (!editing) bar,
      if (!editing && tiles.isNotEmpty)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, t) in tiles.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: t),
              ],
            ],
          ),
        ),
      if (!editing) alert,
      if (!editing) embedded,
      if (!editing) settingsLine,
      footer,
    ];
    return AppHeroCard(
      style: style,
      onTap: onTap,
      padding: padding,
      expanded: rows,
    );
  }
}

class HeroNumber extends StatelessWidget {
  const HeroNumber({
    required this.label,
    required this.value,
    this.color,
    this.target,
    this.onLabelTap,
    super.key,
  });

  final String label;

  final Widget value;

  final Color? color;

  final String? target;

  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onLabelTap == null)
          labelText
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLabelTap,
            child: labelText,
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: DefaultTextStyle.merge(
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                child: value,
              ),
            ),
            if (target != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                target!,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class HeroAmountField extends StatelessWidget {
  const HeroAmountField({
    required this.controller,
    required this.label,
    this.accent,
    this.symbol,
    this.helper,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  final String? helper;

  final Color? accent;
  final String? symbol;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => AppInput(
    controller: controller,
    focusNode: focusNode,
    label: label,
    helper: helper,
    type: AppInputType.amount,
    currencySymbol: symbol ?? UiConfig.stringsOf(context).currencySymbol,
    validator: validator,
    onChanged: onChanged,
    autofocus: autofocus,
    borderColor: accent,
    focusColor: accent,
  );
}

class HeroBar extends StatelessWidget {
  const HeroBar({
    required this.value,
    this.expected,
    this.marker,
    this.ticks = const [],
    this.color,
    this.overColor,
    this.left,
    this.right,
    this.height = 8,
    super.key,
  }) : parts = null;

  const HeroBar.split({
    required List<(double, Color)> this.parts,
    this.left,
    this.right,
    this.height = 8,
    super.key,
  }) : value = 0,
       expected = null,
       marker = null,
       ticks = const [],
       color = null,
       overColor = null;

  final double value;
  final double? expected;
  final double? marker;
  final List<double> ticks;
  final Color? color;
  final Color? overColor;
  final List<(double, Color)>? parts;

  final String? left;
  final String? right;
  final double height;

  @override
  Widget build(BuildContext context) {
    final split = parts;
    if (split == null) {
      return ProgressRow(
        value: value,
        expected: expected,
        marker: marker,
        ticks: ticks,
        color: color,
        overColor: overColor,
        height: height,
        label: left,
        trailing: right,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final caption = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final used = split.fold<double>(0, (s, p) => s + p.$1).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            height: height,
            child: ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (ratio, c) in split)
                    if (ratio > 0)
                      Expanded(
                        flex: (ratio.clamp(0.0, 1.0) * 1000).round().clamp(
                          1,
                          1000,
                        ),
                        child: ColoredBox(color: c),
                      ),
                  Expanded(
                    flex: ((1 - used) * 1000).round().clamp(0, 1000),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (left != null || right != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: _Legend(
                    text: left ?? '',
                    dot: split.first.$2,
                    style: caption,
                  ),
                ),
                if (right != null)
                  _Legend(text: right!, dot: split.last.$2, style: caption),
              ],
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.text, required this.dot, required this.style});

  final String text;
  final Color dot;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    ],
  );
}

class HeroValueLine extends StatelessWidget {
  const HeroValueLine({required this.label, required this.value, super.key});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        DefaultTextStyle.merge(
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          child: value,
        ),
      ],
    );
  }
}

class HeroAlert extends StatelessWidget {
  const HeroAlert({
    required this.text,
    this.onTap,
    this.icon = AppIcons.warning,
    super.key,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: palette.warning,
      fontWeight: FontWeight.w600,
    );
    return Material(
      color: palette.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: palette.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(text, style: style)),
              if (onTap != null)
                Icon(AppIcons.chevronRight, size: 16, color: palette.warning),
            ],
          ),
        ),
      ),
    );
  }
}
