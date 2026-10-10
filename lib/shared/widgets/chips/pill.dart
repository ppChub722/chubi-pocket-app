import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import 'tone.dart';

/// The pill family (owner 2026-10-10) — every rounded label / status /
/// small action / choice in the app is one of the kit pills, by role:
///
/// - **status** ([StatusPill]): dot + label in a tone; tappable = a picker.
/// - **label** ([LabelPill], and [TagPill] for tags): what kind of thing
///   this is — no dot ("ผ่อน", "ธนาคาร", "− รายจ่าย", "#เที่ยว").
/// - **action** ([ActionPill]): icon + label button ("ปรับยอด", "ลบ").
/// - **choice** ([ChoicePill], in a [ChoicePillRow]): one option of a
///   pick-one row ("เดือน · สัปดาห์ · ปี").
///
/// TWO sizes app-wide (owner 2026-10-11) — [PillSize.normal] (32) for
/// every chip and pill, with the same side padding and text, so chips
/// differ only by their label; [PillSize.mini] (20) only for the tags on a
/// transaction list row. [AppBadge] (a counter) stays apart.
enum PillSize {
  /// Tags on a transaction list row — nowhere else.
  mini(height: 20, padding: 6, gap: 3, icon: 11, dot: 5),

  /// Everything else: filter / form / hero / splits chips, status / label
  /// / action / choice pills, dropdown and sort chips, the date pill
  /// ([HeroSpacing.controlHeight]).
  normal(
    height: 32,
    padding: AppSpacing.md,
    gap: AppSpacing.xs,
    icon: 16,
    dot: 8,
  );

  const PillSize({
    required this.height,
    required this.padding,
    required this.gap,
    required this.icon,
    required this.dot,
  });

  /// Minimum height (text scaling can grow it).
  final double height;

  /// Side padding.
  final double padding;

  /// Space between icon / dot and label.
  final double gap;
  final double icon;
  final double dot;

  /// The label's text style — colour is the pill's own; every chip uses
  /// the same weight ([chipWeight]) so a selection never changes its width.
  TextStyle? textStyle(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return switch (this) {
      mini => t.labelSmall?.copyWith(fontSize: 10, height: 1.2),
      normal => t.labelLarge,
    };
  }

  /// The one label weight of a chip.
  static const FontWeight chipWeight = FontWeight.w600;
}

/// The shape every pill shares: stadium, [PillSize] height and padding,
/// optional tap. Kit-internal — use the role widgets.
class PillShell extends StatelessWidget {
  const PillShell({
    required this.size,
    required this.background,
    required this.child,
    this.border,
    this.onTap,
    this.elevation = 0,
    super.key,
  });

  final PillSize size;
  final Color background;
  final Color? border;
  final VoidCallback? onTap;
  final double elevation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: background,
      elevation: elevation,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: StadiumBorder(
        side: border == null ? BorderSide.none : BorderSide(color: border!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.padding),
            child: Row(mainAxisSize: MainAxisSize.min, children: [child]),
          ),
        ),
      ),
    );
  }
}

/// `[icon] label` on one line, ellipsised — the inside of every pill.
class PillContent extends StatelessWidget {
  const PillContent({
    required this.label,
    required this.color,
    required this.size,
    this.leading,
    this.trailing,
    this.weight = PillSize.chipWeight,
    super.key,
  });

  final String label;
  final Color color;
  final PillSize size;
  final Widget? leading;
  final Widget? trailing;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: size.gap)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: size
                  .textStyle(context)
                  ?.copyWith(color: color, fontWeight: weight),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 2), trailing!],
        ],
      ),
    );
  }
}

/// What kind of thing this is — "ผ่อน", "ธนาคาร", "− รายจ่าย" — no dot.
///
/// Colour: [tone] (neutral = quiet grey on the surface tint), or an exact
/// [color] (a wallet's accent, a category's colour). [outlined] adds a
/// border in that colour — the stronger look for a header.
class LabelPill extends StatelessWidget {
  const LabelPill({
    required this.label,
    this.icon,
    this.tone = Tone.neutral,
    this.color,
    this.outlined = false,
    this.size = PillSize.normal,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Tone tone;

  /// Overrides [tone].
  final Color? color;
  final bool outlined;
  final PillSize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neutral = color == null && tone == Tone.neutral;
    final fg = color ?? tone.color(context);
    return PillShell(
      size: size,
      background: neutral
          ? scheme.surfaceContainerHighest
          : fg.withValues(alpha: 0.14),
      border: outlined ? fg.withValues(alpha: 0.35) : null,
      onTap: onTap,
      child: PillContent(
        label: label,
        color: fg,
        size: size,
        leading: icon == null ? null : Icon(icon, size: size.icon, color: fg),
      ),
    );
  }
}

/// One option of a pick-one row of pills — "เดือน · สัปดาห์ · ปี",
/// "ใหม่สุด · เก่าสุด" (the filter sheet). [selected] = primary-tinted fill,
/// border and text; otherwise a quiet outline. The kit's answer to a
/// Material ChoiceChip, [PillSize.normal].
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  static const size = PillSize.normal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: PillShell(
        size: size,
        background: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        border: selected ? scheme.primary : scheme.outlineVariant,
        onTap: onTap,
        child: PillContent(
          label: label,
          color: fg,
          size: size,
          leading: icon == null ? null : Icon(icon, size: size.icon, color: fg),
        ),
      ),
    );
  }
}

/// A row of [ChoicePill]s, one of [values] selected; wraps when long.
/// [reselect] values fire [onSelected] again when tapped while selected
/// (กำหนดเอง re-opens its range picker).
class ChoicePillRow<T> extends StatelessWidget {
  const ChoicePillRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.reselect,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final bool Function(T)? reselect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final v in values)
          ChoicePill(
            label: label(v),
            selected: v == selected,
            onTap: () {
              if (v != selected || (reselect?.call(v) ?? false)) {
                onSelected(v);
              }
            },
          ),
      ],
    );
  }
}

/// A tag as a pill — `[glyph] #name` on a tint of the tag's own colour.
/// Kit-level: callers resolve [color] / [glyph] from the tag (the tags
/// feature's `tagColor`). The owner is trying a row of these ([mini]) on
/// transaction rows instead of the coloured `#tag` text line.
class TagPill extends StatelessWidget {
  const TagPill({
    required this.name,
    required this.color,
    this.glyph,
    this.size = PillSize.mini,
    this.onTap,
    super.key,
  });

  final String name;
  final Color color;
  final IconData? glyph;
  final PillSize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PillShell(
      size: size,
      background: color.withValues(alpha: 0.16),
      onTap: onTap,
      child: PillContent(
        label: '#$name',
        color: color,
        size: size,
        leading: glyph == null
            ? null
            : Icon(glyph, size: size.icon, color: color),
      ),
    );
  }
}

/// The first [maxVisible] of [pills] on one line, then a neutral `+n` for
/// the rest — tags on a dense row. Pills shrink (ellipsis) before they
/// overflow, so give it a bounded width (inside an `Expanded` / `Flexible`).
class PillOverflowRow extends StatelessWidget {
  const PillOverflowRow({
    required this.pills,
    this.maxVisible = 2,
    this.size = PillSize.mini,
    super.key,
  });

  final List<Widget> pills;
  final int maxVisible;

  /// Size of the `+n` pill — match [pills].
  final PillSize size;

  @override
  Widget build(BuildContext context) {
    final shown = pills.take(maxVisible).toList();
    final rest = pills.length - shown.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, p) in shown.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Flexible(child: p),
        ],
        if (rest > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          LabelPill(label: '+$rest', size: size),
        ],
      ],
    );
  }
}
