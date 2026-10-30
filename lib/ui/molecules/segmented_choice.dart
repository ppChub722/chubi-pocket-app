import 'package:flutter/material.dart';

import '../atoms/busy_scope.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

class ChoiceSegment<T> {
  const ChoiceSegment(this.value, this.label);

  final T value;
  final String label;
}

class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.expand = false,
    super.key,
  }) : assert(segments.length >= 2, 'SegmentedChoice needs 2+ segments');

  final List<ChoiceSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  /// Full width, equal segments, a larger label: a page's top tabs
  /// (ภาพรวม | ปฏิทิน).
  final bool expand;

  // Faded and inert under a locked [BusyScope] (a save runs elsewhere).
  @override
  Widget build(BuildContext context) => BusyLock(
    locked: enabled && BusyScope.isLocked(context),
    child: _build(context),
  );

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final text = expand ? textTheme.titleSmall : textTheme.labelMedium;
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
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              for (final s in segments)
                if (expand)
                  Expanded(
                    child: _Segment(
                      label: s.label,
                      on: s.value == selected,
                      style: text,
                      centered: true,
                      onTap: enabled && s.value != selected
                          ? () => onChanged(s.value)
                          : null,
                    ),
                  )
                else
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
    this.centered = false,
  });

  final String label;
  final bool on;
  final TextStyle? style;
  final VoidCallback? onTap;
  final bool centered;

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
              textAlign: centered ? TextAlign.center : null,
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
