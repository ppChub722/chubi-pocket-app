import 'package:flutter/material.dart';

enum PpForgeSpinnerSize {
  small(16, 2),
  medium(24, 2.5),
  large(36, 3.5);

  const PpForgeSpinnerSize(this.dimension, this.stroke);
  final double dimension;
  final double stroke;
}

class PpForgeSpinner extends StatelessWidget {
  const PpForgeSpinner({
    this.size = PpForgeSpinnerSize.medium,
    this.color,
    this.value,
    super.key,
  });

  final PpForgeSpinnerSize size;

  final Color? color;

  final double? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size.dimension,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: size.stroke,
        color: color,
      ),
    );
  }
}
