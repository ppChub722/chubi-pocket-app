import 'package:flutter/material.dart';

import '../atoms/busy_scope.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

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

  final Color? color;
  final String? description;
}

class SelectCardGroup<T> extends StatelessWidget {
  const SelectCardGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.columns,
    super.key,
  });

  final List<SelectCardOption<T>> options;
  final T selected;

  final ValueChanged<T>? onChanged;

  final int? columns;

  static const washFrom = 0.18;
  static const washTo = 0.06;

  // Faded and inert under a locked [BusyScope] (a save runs elsewhere).
  @override
  Widget build(BuildContext context) => BusyLock(
    locked: onChanged != null && BusyScope.isLocked(context),
    child: _build(context),
  );

  Widget _build(BuildContext context) {
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

  static Color readable(Color accent, Color bg) {
    var hsl = HSLColor.fromColor(accent);
    final lighten = bg.computeLuminance() < 0.4;
    double ratio(Color a, Color b) {
      final l1 = a.computeLuminance();
      final l2 = b.computeLuminance();
      final hi = l1 > l2 ? l1 : l2;
      final lo = l1 > l2 ? l2 : l1;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (var i = 0; i < 14 && ratio(hsl.toColor(), bg) < 4.5; i++) {
      hsl = hsl.withLightness(
        (hsl.lightness + (lighten ? 0.04 : -0.04)).clamp(0.0, 1.0),
      );
    }
    return hsl.toColor();
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
    final dim = onChanged == null ? 0.55 : 1.0;
    final washed = Color.alphaBlend(
      accent.withValues(alpha: washFrom),
      scheme.surfaceContainerLow,
    );
    final ink = active ? readable(accent, washed) : scheme.onSurface;

    final label = Text(
      o.label,
      textAlign: stacked ? TextAlign.center : TextAlign.start,
      style: textTheme.titleSmall?.copyWith(
        color: active ? ink.withValues(alpha: dim) : scheme.onSurface,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    final description = o.description == null
        ? null
        : Text(
            o.description!,
            textAlign: stacked ? TextAlign.center : TextAlign.start,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          );
    final disc = stacked ? 44.0 : 36.0;
    final iconDisc = o.icon == null
        ? null
        : AnimatedContainer(
            duration: _motion,
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? accent.withValues(alpha: 0.16 * dim)
                  : scheme.surfaceContainerHighest,
            ),
            child: Icon(
              o.icon,
              size: stacked ? 24 : 20,
              color: active
                  ? ink.withValues(alpha: dim)
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
        color: active ? null : scheme.surfaceContainerLow,
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: washFrom * dim),
                  accent.withValues(alpha: washTo * dim),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: active ? accent.withValues(alpha: dim) : scheme.outlineVariant,
          width: active ? 2 : 1,
        ),
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
