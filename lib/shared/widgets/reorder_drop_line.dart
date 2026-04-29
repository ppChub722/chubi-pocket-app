import 'package:flutter/material.dart';

/// Horizontal drop-line indicator used by reorder UIs to show where the
/// dragged item will land. Color flips red when [isValid] is false so
/// users see invalid drops at hover time, not after release.
///
/// Generic over the data type — used today by categories' tree reorder,
/// reusable for any future reorder surface (tags, accounts, projects).
class ReorderDropLine extends StatelessWidget {
  const ReorderDropLine({
    required this.depth,
    required this.isValid,
    this.indentPerDepth = 24.0,
    this.baseIndent = 16.0,
    this.height = 4.0,
    super.key,
  });

  /// 1-indexed (1 = root, 2 = child, ...). Drives the leading indent so
  /// the line sits under the right column lane.
  final int depth;

  /// Drives the line's color. When false, the resolver has rejected this
  /// move (cycle, depth overflow, level skip) — UX should prevent the
  /// drop, not just snackbar after.
  final bool isValid;

  /// Width of one depth step. Match the consumer's row indent so the
  /// line aligns visually with where the dropped item would render.
  final double indentPerDepth;

  /// Left/right padding that wraps every depth step. Should match the
  /// consumer's outer list padding.
  final double baseIndent;

  /// How tall the line is. Slightly above 1 px reads cleanly on dense
  /// screens; default 4 dp is what categories uses.
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isValid ? scheme.primary : scheme.error;
    final indent = baseIndent + (depth - 1) * indentPerDepth;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        height: height,
        margin: EdgeInsets.only(left: indent, right: baseIndent),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
