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
    this.cornerOffset = 0,
    this.strokeWidth = 1.5,
    super.key,
  });

  final Widget child;
  final double angleDegrees;

  /// Toggle the L-bracket overlay independently of the tilt.
  final bool showCornerMark;

  /// Side length of each L corner bracket.
  final double cornerSize;

  /// How far the corner brackets sit from the child's edge.
  /// - `0` (default): brackets sit *at* the child's bounding-box corners,
  ///   staying within the layout's vertical bounds. For round children
  ///   (e.g. a 36×36 icon circle), this places the L brackets in the
  ///   transparent corners between the circle and its bounding box.
  /// - `> 0`: brackets sit `cornerOffset` dp outside the bounding box.
  ///   Looks like a viewfinder, but bleeds into adjacent rows visually.
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
