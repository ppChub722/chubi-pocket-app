import 'package:flutter/material.dart';

import '../../tokens/hero_metrics.dart';

/// 2–4 tiles in one hero row, equal width and as tall as the tallest
/// ([SummaryTileView]s, pick cards, any tile).
class HeroTiles extends StatelessWidget {
  const HeroTiles({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
}
