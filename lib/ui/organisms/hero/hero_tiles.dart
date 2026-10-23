import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/hero_colors.dart';
import '../../tokens/hero_metrics.dart';

/// 2–4 tiles in one hero row, equal width and as tall as the tallest
/// ([SummaryTileView]s, pick cards, any tile). [joined]: one inset box split
/// by lines, the tiles drawn flat inside it.
class HeroTiles extends StatelessWidget {
  const HeroTiles({required this.children, this.joined = false, super.key});

  final List<Widget> children;
  final bool joined;

  /// True inside a joined [HeroTiles]: a tile draws no card of its own.
  static bool joinedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_JoinedScope>() != null;

  @override
  Widget build(BuildContext context) {
    if (joined) return _joined(context);
    // Tiles sit as far apart as they sit from the card's edge.
    final gap = HeroMetrics.of(context).padding.left;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, t) in children.indexed) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(child: t),
          ],
        ],
      ),
    );
  }

  Widget _joined(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    final line = hero?.line ?? scheme.outlineVariant;
    final radius = BorderRadius.circular(AppRadius.lg);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hero?.insetOrSoft ?? scheme.surfaceContainer,
        border: Border.all(color: line),
        borderRadius: radius,
      ),
      child: _JoinedScope(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, t) in children.indexed) ...[
                if (i > 0) VerticalDivider(width: 1, thickness: 1, color: line),
                Expanded(child: t),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinedScope extends InheritedWidget {
  const _JoinedScope({required super.child});

  @override
  bool updateShouldNotify(_JoinedScope old) => false;
}
