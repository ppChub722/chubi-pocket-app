import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Where a [MilestoneStep] stands.
enum MilestoneState {
  /// Reached — a filled disc.
  done,

  /// The next one to reach — a ringed disc in the accent.
  next,

  /// Not yet — a quiet outline.
  todo,
}

/// One step of a [MilestoneRow]: a [glyph] ("✓", "75", "🏁") in a disc and a
/// [label] under it ("25%", "฿60,000").
class MilestoneStep {
  const MilestoneStep({
    required this.label,
    required this.state,
    required this.glyph,
  });

  final String label;
  final MilestoneState state;
  final String glyph;
}

/// Milestones of a goal (25 / 50 / 75 / 100 %): n equal steps side by side,
/// each a disc with a glyph and a caption — done = filled [color], next =
/// ringed, todo = grey. Plain strings in; the caller works out the states.
class MilestoneRow extends StatelessWidget {
  const MilestoneRow({required this.steps, this.color, super.key});

  final List<MilestoneStep> steps;

  /// The accent (defaults to the primary colour).
  final Color? color;

  /// Disc diameter.
  static const double disc = 28;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = color ?? scheme.primary;
    return Row(
      children: [
        for (final s in steps)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _disc(context, s, accent),
                const SizedBox(height: PpForgeSpacing.xs),
                Text(
                  s.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: s.state == MilestoneState.todo
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                    fontWeight: s.state == MilestoneState.next
                        ? FontWeight.w700
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _disc(BuildContext context, MilestoneStep s, Color accent) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (Color fill, Color border, Color fg) = switch (s.state) {
      MilestoneState.done => (accent, accent, scheme.onPrimary),
      MilestoneState.next => (accent.withValues(alpha: 0.14), accent, accent),
      MilestoneState.todo => (
        Colors.transparent,
        scheme.outlineVariant,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      width: disc,
      height: disc,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: fill,
        shape: CircleBorder(
          side: BorderSide(
            color: border,
            width: s.state == MilestoneState.next ? 2 : 1.5,
          ),
        ),
      ),
      child: Text(
        s.glyph,
        style: text.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
