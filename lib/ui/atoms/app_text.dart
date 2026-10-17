import 'package:flutter/material.dart';

import '../tokens/typography.dart';

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    this.role = AppTextRole.body,
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
  final AppTextRole role;
  final Color? color;
  final FontWeight? weight;

  final bool italic;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    var style = AppTypography.of(context, role);
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
