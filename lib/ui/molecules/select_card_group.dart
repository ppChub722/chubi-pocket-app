import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// One option of a [SelectCardGroup].
class SelectCardOption<T> {
  const SelectCardOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.description,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// This option's accent when selected (expense red / income green, a
  /// wallet type's group colour). Defaults to the primary colour.
  final Color? color;
  final String? description;
}

/// How the SELECTED card is drawn.
enum SelectCardStyle {
  /// Today: a tinted fill + an accent border + a filled icon disc.
  tinted,

  /// PROPOSED (owner 2026-10-12): a clear gradient fill in the option's tone
  /// (the wallet card / tinted hero family), white / on-colour text and icon,
  /// no glow border. Disabled + picked = a muted version of the same gradient.
  gradient,
}

/// Big choice cards for a mutually exclusive, high-stakes choice at the top
/// of a form ("ฉันติดเขา / เขาติดฉัน", expense / income). Bigger and more
/// explicit than a segmented button.
///
/// Default: one row, side by side (icon left of the label). [columns] wraps
/// the options into a grid of that many per row — each card stacks its icon
/// above the label, and a short last row stretches to fill (5 options at
/// `columns: 3` → 3 + 2, e.g. the wallet type picker).
///
/// Selected = highlight only (owner 2026-10-11, the app's no-✓ rule): a
/// tinted fill, an accent border and a filled icon disc, in the option's
/// own [SelectCardOption.color]. No check badge.
class SelectCardGroup<T> extends StatelessWidget {
  const SelectCardGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.columns,
    this.style = SelectCardStyle.tinted,
    super.key,
  });

  /// How the selected card looks ([SelectCardStyle.tinted] until the owner
  /// adopts the gradient).
  final SelectCardStyle style;

  final List<SelectCardOption<T>> options;
  final T selected;

  /// null → read-only (e.g. type locked after create).
  final ValueChanged<T>? onChanged;

  /// Cards per row; null = all options in one row.
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final perRow = columns;
    if (perRow == null || perRow <= 0) {
      return _row(context, options, stacked: false);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var start = 0; start < options.length; start += perRow) ...[
          if (start > 0) const SizedBox(height: AppSpacing.sm),
          _row(
            context,
            options.sublist(start, (start + perRow).clamp(0, options.length)),
            stacked: true,
          ),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    List<SelectCardOption<T>> items, {
    required bool stacked,
  }) {
    // Equal-height cards within a row, whatever the label length.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: _card(context, items[i], stacked: stacked)),
          ],
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    SelectCardOption<T> o, {
    required bool stacked,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = o.value == selected;
    final accent = o.color ?? scheme.primary;
    final grad = style == SelectCardStyle.gradient && active;
    // Gradient: lighter top-left → deeper bottom-right of the accent; picked
    // but read-only = the same gradient washed toward the surface.
    final hsl = HSLColor.fromColor(accent);
    Color shade(double dl) =>
        hsl.withLightness((hsl.lightness + dl).clamp(0.0, 1.0)).toColor();
    Color mute(Color c) => onChanged == null
        ? Color.lerp(c, scheme.surfaceContainerHighest, 0.55)!
        : c;
    final gFrom = mute(shade(0.07));
    final gTo = mute(shade(-0.09));
    final onGrad = onChanged == null
        ? scheme.onSurface
        : ThemeData.estimateBrightnessForColor(Color.lerp(gFrom, gTo, 0.5)!) ==
              Brightness.dark
        ? Colors.white
        : Colors.black87;
    final label = Text(
      o.label,
      textAlign: stacked ? TextAlign.center : TextAlign.start,
      style: textTheme.titleSmall?.copyWith(
        color: grad
            ? onGrad
            : active
            ? accent
            : scheme.onSurface,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    final description = o.description == null
        ? null
        : Text(
            o.description!,
            textAlign: stacked ? TextAlign.center : TextAlign.start,
            style: textTheme.bodySmall?.copyWith(
              color: grad
                  ? onGrad.withValues(alpha: 0.85)
                  : scheme.onSurfaceVariant,
            ),
          );
    // Ink that reads on the accent fill.
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    // The icon sits in a disc: filled with the accent once picked.
    final disc = stacked ? 44.0 : 36.0;
    final iconDisc = o.icon == null
        ? null
        : AnimatedContainer(
            duration: _motion,
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: grad
                  ? onGrad.withValues(alpha: 0.22)
                  : active
                  ? accent
                  : scheme.surfaceContainerHighest,
            ),
            child: Icon(
              o.icon,
              size: stacked ? 24 : 20,
              color: grad
                  ? onGrad
                  : active
                  ? onAccent
                  : scheme.onSurfaceVariant,
            ),
          );

    final Widget content;
    if (stacked) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconDisc != null) ...[
            iconDisc,
            const SizedBox(height: AppSpacing.sm),
          ],
          label,
          ?description,
        ],
      );
    } else {
      content = Row(
        children: [
          if (iconDisc != null) ...[
            iconDisc,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [label, ?description],
            ),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: _motion,
      decoration: BoxDecoration(
        color: grad
            ? null
            : active
            ? accent.withValues(alpha: 0.10)
            : scheme.surfaceContainerLow,
        gradient: grad
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gFrom, gTo],
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        // The gradient card keeps a 1-px (clear) border, so the card never
        // changes size between states and there is no glow edge.
        border: Border.all(
          color: grad
              ? Colors.transparent
              : active
              ? accent
              : scheme.outlineVariant,
          width: grad ? 1 : (active ? 2 : 1),
        ),
        boxShadow: [
          if (active && !grad)
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onChanged == null ? null : () => onChanged!(o.value),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: stacked ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  static const _motion = Duration(milliseconds: 200);
}
