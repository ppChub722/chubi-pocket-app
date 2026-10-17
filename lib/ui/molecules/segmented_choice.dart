import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// One choice of a [SegmentedChoice].
class ChoiceSegment<T> {
  const ChoiceSegment(this.value, this.label);

  final T value;
  final String label;
}

/// A compact connected control that picks ONE of 2-4 short options — the
/// notification settings' ปิด / แจ้ง / อัตโนมัติ. The chosen segment is
/// highlighted (never a ✓). Not for proportions ([SegmentedBar]) or an
/// icon-led theme pick ([ThemeModeChips]).
///
///   ( ปิด | [แจ้ง] | อัตโนมัติ )
///
/// [onChanged] fires only for a segment that is not already chosen.
/// [enabled] false fades it and ignores taps.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  }) : assert(segments.length >= 2, 'SegmentedChoice needs 2+ segments');

  final List<ChoiceSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.labelMedium;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in segments)
                _Segment(
                  label: s.label,
                  on: s.value == selected,
                  style: text,
                  onTap: enabled && s.value != selected
                      ? () => onChanged(s.value)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.on,
    required this.style,
    required this.onTap,
  });

  final String label;
  final bool on;
  final TextStyle? style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: on ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: style?.copyWith(
                color: on ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
