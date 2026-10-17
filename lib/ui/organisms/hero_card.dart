import 'package:flutter/material.dart';

import '../atoms/app_input.dart';
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

/// The detail-page hero card (owner 2026-10-17, reference "Chubi Page
/// Reference" §0): ONE API for the same rows, in the same order, on every
/// detail page.
///
/// ```
/// A  [chips…]                              [links] [🔍] [✏️]   ← top row
/// B  (icon)  description (≤ 2 lines)            people: name + fact
/// C  small label
///    ฿5,100  / target                          ← the main number, full width
/// D  ▓▓▓▓▓▒▒▒░░░░  pace tick / 25-50-75 ticks / split
///    caption left                  caption right
/// E  [tile] [tile] [tile]                      ← 2–4 tappable tiles
/// F  ⚠ amber alert line
/// G  embedded tool (the debt summary message)
///    settings summary line
/// ```
///
/// Rows that are null / empty are skipped (A collapses when it has nothing).
/// The name is NOT in the card (it is in the top bar); only people pages
/// pass [name] + [fact].
///
/// **Edit variant** ([editing] true): the same card, but A shows only the
/// editable [chips] (dropdowns — the page passes them), no action slot; B is
/// the [icon] (the page wraps it in an `EditableCircle` with ✎) beside the
/// underlined [name] and [description] inputs; C is the outlined
/// [amountField] (only when the number is user-set); D–G and the settings
/// line are hidden.
///
/// The ✏️ is a [CardActionButton] — the same 40 px slot as the list cards.
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
    this.onTap,
    super.key,
  });

  final HeroStyle style;

  /// Edit variant (see above).
  final bool editing;

  /// Row A, left: status ▾ → type → period / date / ref (`AppChip`s; in edit
  /// mode only the editable ones, as dropdown chips).
  final List<Widget> chips;

  /// Row A, right, first: page links (🪪 contact …) — `CardActionButton`s.
  final List<Widget> links;

  /// Row A, right, after the links: the 🔍 `ToolbarToggleButton`.
  final Widget? search;

  /// Far right: shows the ✏️ (view mode). Null hides it.
  final VoidCallback? onEdit;

  /// Row B: the entity's icon (40 in view; the page passes the 44 editable
  /// circle in edit).
  final Widget? icon;

  /// People pages (view) show the name + a short [fact] instead of a bare
  /// description; edit mode: the underlined name input.
  final Widget? name;
  final Widget? fact;

  /// Row B: the description (`HeroDescription`, which is the underlined input
  /// in edit mode).
  final Widget? description;

  /// Row C (view): a [HeroNumber].
  final Widget? number;

  /// Row C (edit): a [HeroAmountField] — only when the number is user-set.
  final Widget? amountField;

  /// Row D: a [HeroBar].
  final Widget? bar;

  /// Row E: 2–4 tiles, equal width (`SummaryTile`s from the list summary
  /// card, or any tile widget).
  final List<Widget> tiles;

  /// Row F: a [HeroAlert].
  final Widget? alert;

  /// Row G: an embedded tool.
  final Widget? embedded;

  /// The bottom line: a small summary of the settings ("นับ: … · เตือนที่ 80%").
  final Widget? settingsLine;
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
    final actions = editing
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
      identity,
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
    ];
    return HeroSurface(
      style: style,
      onTap: onTap,
      child: HeroContent(rows: rows),
    );
  }
}

/// Hero row C: a small label, then the big number on its own full-width row
/// (never beside the icon), in a semantic colour, with an optional muted
/// "/ target · 65%" after it.
class HeroNumber extends StatelessWidget {
  const HeroNumber({
    required this.label,
    required this.value,
    this.color,
    this.target,
    this.onLabelTap,
    super.key,
  });

  /// "ใช้ไป", "ออมแล้ว", "ยังใช้ได้".
  final String label;

  /// The number — a `MoneyText` (or any text widget); it is styled big here.
  final Widget value;

  /// Semantic colour (income green / expense red / the entity tint).
  final Color? color;

  /// "/ ฿80,000 · 65%".
  final String? target;

  /// Makes the label a link ("ต.ค. ใช้ไป · 12 รายการ ›").
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

/// Hero row C in EDIT mode: the outlined amount field on the tint (no white
/// box) — only for a number the user sets (a budget limit, a goal target, a
/// recurring amount, an event's planned budget).
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

  /// A muted line under the field ("What you intend to spend").
  final String? helper;

  /// Outline colour (the hero's tint); null = the theme's.
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

/// Hero row D: ONE bar with a caption line under it. Variants: a plain /
/// pace-tick bar (`marker`), a 25-50-75 bar (`ticks`), a split bar
/// ([HeroBar.split], two parts), each with a left and a right caption.
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

  /// A bar split in parts, each (ratio of the whole, colour) — wallet
  /// "ใช้ได้ / ออมไว้", an event's paid / unpaid.
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

  /// Caption under the bar, left / right.
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
                  // The unfilled rest of the track.
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
                  child: Text(
                    left ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: caption,
                  ),
                ),
                if (right != null) Text(right!, style: caption),
              ],
            ),
          ),
      ],
    );
  }
}

/// A small "label ... value" line on a hero (the embedded slot): a muted
/// [label] at the left, the [value] (a `MoneyText`, any text widget) at the
/// right — an extra fact that is not worth a tile ("รายรับรวม +฿500").
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

/// Hero row F: ONE amber line for something to act on (a due date, "รอใส่ยอด",
/// "ค้างเกิน 30 วัน"). Tappable when [onTap] is given.
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
