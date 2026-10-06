import 'package:flutter/material.dart';

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

/// Big side-by-side choice cards for a mutually exclusive, high-stakes
/// choice at the top of a form ("ฉันติดเขา / เขาติดฉัน", expense / income).
/// Bigger and more explicit than a segmented button.
class SelectCardGroup<T> extends StatelessWidget {
  const SelectCardGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<SelectCardOption<T>> options;
  final T selected;

  /// null → read-only (e.g. type locked after create).
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _card(context, options[i])),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, SelectCardOption<T> o) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = o.value == selected;
    final accent = o.color ?? scheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: active ? accent : scheme.outlineVariant,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onChanged == null ? null : () => onChanged!(o.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                if (o.icon != null) ...[
                  Icon(o.icon,
                      color: active ? accent : scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        o.label,
                        style: textTheme.titleSmall?.copyWith(
                          color: active ? accent : scheme.onSurface,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (o.description != null)
                        Text(
                          o.description!,
                          style: textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
