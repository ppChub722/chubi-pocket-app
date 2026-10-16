import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Horizontal row of filter chips (+ optional trailing sort chip) that
/// scrolls sideways when it overflows — the toolbar row under a search bar.
class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.chips,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      PpForgeSpacing.lg,
      PpForgeSpacing.xs,
      PpForgeSpacing.md,
      PpForgeSpacing.xs,
    ),
    super.key,
  });

  final EdgeInsetsGeometry padding;

  final List<Widget> chips;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            // The chips scroll sideways; the right edge fades so a chip that
            // runs off the viewport reads as scrolling, not as a clipped chip.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) {
                final fade = r.width <= 24 ? 0.0 : 20 / r.width;
                return LinearGradient(
                  colors: const [
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 1 - fade, 1],
                ).createShader(r);
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < chips.length; i++) ...[
                      if (i > 0) const SizedBox(width: PpForgeSpacing.sm),
                      chips[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: PpForgeSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
