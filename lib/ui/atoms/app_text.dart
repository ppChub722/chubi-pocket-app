import 'package:flutter/material.dart';

import '../tokens/typography.dart';

/// Text in one of the seven roles ([PpForgeTextRole]) — the only way features
/// write words (owner 2026-10-12). [color], [weight] and the layout options
/// tune a role without leaving it.
class PpForgeText extends StatelessWidget {
  const PpForgeText(
    this.text, {
    this.role = PpForgeTextRole.body,
    this.color,
    this.weight,
    this.italic = false,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
    super.key,
  });

  final String text;
  final PpForgeTextRole role;
  final Color? color;
  final FontWeight? weight;

  /// Slanted (a note, a muted aside). The Thai font has no true italic:
  /// Flutter slants it synthetically.
  final bool italic;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    var style = PpForgeTypography.of(context, role);
    if (color != null || weight != null || italic) {
      style = style?.copyWith(
        color: color,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : null,
      );
    }
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines == null ? null : TextOverflow.ellipsis),
      textAlign: textAlign,
      softWrap: softWrap,
    );
  }
}
