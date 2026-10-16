import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// The one hairline (owner 2026-10-12): a 1-px line in the outline colour.
/// `PpForgeDivider()` spans its width; `PpForgeDivider.row()` is inset like the
/// rows of a detail section (a rule between rows); [height] is the space it
/// takes (the line sits in the middle). Never a raw `Divider`.
class PpForgeDivider extends StatelessWidget {
  const PpForgeDivider({this.height = 1, this.indent = 0, super.key});

  /// Between the rows of a section: inset [PpForgeSpacing.lg] on both sides.
  const PpForgeDivider.row({super.key})
    : height = 1,
      indent = PpForgeSpacing.lg;

  /// The space the divider takes up (the line is centred in it).
  final double height;

  /// Inset from both ends.
  final double indent;

  @override
  Widget build(BuildContext context) => Divider(
    height: height,
    thickness: 1,
    indent: indent,
    endIndent: indent,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}
