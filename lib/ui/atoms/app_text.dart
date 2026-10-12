import 'package:flutter/material.dart';

import '../tokens/typography.dart';

/// Text in one of the seven roles ([AppTextRole]) — the only way features
/// write words (owner 2026-10-12). [color], [weight] and the layout options
/// tune a role without leaving it.
class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    this.role = AppTextRole.body,
    this.color,
    this.weight,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
    super.key,
  });

  final String text;
  final AppTextRole role;
  final Color? color;
  final FontWeight? weight;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    var style = AppTypography.of(context, role);
    if (color != null || weight != null) {
      style = style?.copyWith(color: color, fontWeight: weight);
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
