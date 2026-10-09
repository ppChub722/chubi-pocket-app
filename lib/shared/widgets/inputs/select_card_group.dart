import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

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

  /// Accent when selected (e.g. expense red / income green). Defaults to
  /// the primary colour.
  final Color? color;
  final String? description;
}

/// Big choice cards for a mutually exclusive, high-stakes choice at the top
/// of a form ("ฉันติดเขา / เขาติดฉัน", expense / income). Bigger and more
/// explicit than a segmented button.
///
/// Default: one row, side by side (icon left of the label). [columns] wraps
/// the options into a grid of that many per row — each card stacks its icon
/// above the label, and a short last row stretches to fill (5 options at
/// `columns: 3` → 3 + 2, e.g. the wallet type picker).
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
    final label = Text(
      o.label,
      textAlign: stacked ? TextAlign.center : TextAlign.start,
      style: textTheme.titleSmall?.copyWith(
        color: active ? accent : scheme.onSurface,
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
              color: active ? accent : scheme.surfaceContainerHighest,
            ),
            child: Icon(
              o.icon,
              size: stacked ? 24 : 20,
              color: active ? onAccent : scheme.onSurfaceVariant,
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

    final card = AnimatedContainer(
      duration: _motion,
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: 0.10)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: active ? accent : scheme.outlineVariant,
          width: active ? 2 : 1,
        ),
        boxShadow: [
          if (active)
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
    // ✓ in the corner of the picked one.
    return Stack(
      // Passthrough: the row stretches the card to equal heights.
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: AppSpacing.xs + 2,
          right: AppSpacing.xs + 2,
          child: AnimatedScale(
            duration: _motion,
            curve: Curves.easeOutBack,
            scale: active ? 1 : 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: Icon(AppIcons.check, size: 12, color: onAccent),
            ),
          ),
        ),
      ],
    );
  }

  static const _motion = Duration(milliseconds: 200);
}
