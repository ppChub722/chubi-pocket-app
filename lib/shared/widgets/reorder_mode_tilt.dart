import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual cue that a row is grabbable in reorder mode.
///
/// Applies a subtle 2° tilt to [child] and overlays four small L-shaped
/// corner brackets (viewfinder-reticle style). The brackets sit just
/// outside the child's bounding box and signal "this is selected /
/// movable", matching how camera viewfinders mark a focus area.
///
/// Drop-in wrapper around any icon / avatar widget.
class ReorderModeTilt extends StatelessWidget {
  const ReorderModeTilt({
    required this.child,
    this.angleDegrees = -2,
    this.showCornerMark = true,
    this.cornerSize = 6,
    this.cornerOffset = 3,
    this.strokeWidth = 1.5,
    super.key,
  });

  final Widget child;
  final double angleDegrees;

  /// Toggle the L-bracket overlay independently of the tilt.
  final bool showCornerMark;

  /// Side length of each L corner bracket.
  final double cornerSize;

  /// Distance from the child's edge to where each L sits (negative
  /// position relative to child bounds).
  final double cornerOffset;

  /// Border thickness of each L stroke.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDegrees * math.pi / 180,
      child: showCornerMark
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                Positioned(
                  top: -cornerOffset,
                  left: -cornerOffset,
                  child: _CornerBracket(
                    size: cornerSize,
                    stroke: strokeWidth,
                    showTop: true,
                    showLeft: true,
                  ),
                ),
                Positioned(
                  top: -cornerOffset,
                  right: -cornerOffset,
                  child: _CornerBracket(
                    size: cornerSize,
                    stroke: strokeWidth,
                    showTop: true,
                    showRight: true,
                  ),
                ),
                Positioned(
                  bottom: -cornerOffset,
                  left: -cornerOffset,
                  child: _CornerBracket(
                    size: cornerSize,
                    stroke: strokeWidth,
                    showBottom: true,
                    showLeft: true,
                  ),
                ),
                Positioned(
                  bottom: -cornerOffset,
                  right: -cornerOffset,
                  child: _CornerBracket(
                    size: cornerSize,
                    stroke: strokeWidth,
                    showBottom: true,
                    showRight: true,
                  ),
                ),
              ],
            )
          : child,
    );
  }
}

/// One L-shaped bracket — a small square with two visible borders
/// meeting at the corner. Pure paint via `Border` sides; no
/// CustomPainter needed.
class _CornerBracket extends StatelessWidget {
  const _CornerBracket({
    required this.size,
    required this.stroke,
    this.showTop = false,
    this.showRight = false,
    this.showBottom = false,
    this.showLeft = false,
  });

  final double size;
  final double stroke;
  final bool showTop;
  final bool showRight;
  final bool showBottom;
  final bool showLeft;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final on = BorderSide(color: color, width: stroke);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: showTop ? on : BorderSide.none,
          right: showRight ? on : BorderSide.none,
          bottom: showBottom ? on : BorderSide.none,
          left: showLeft ? on : BorderSide.none,
        ),
      ),
    );
  }
}
