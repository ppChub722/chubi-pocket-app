import 'package:flutter/material.dart';

class AmountText extends StatelessWidget {
  const AmountText(
    this.text, {
    this.color,
    this.style,
    this.textAlign,
    super.key,
  });

  final String text;
  final Color? color;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(
        color: color ?? base.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
