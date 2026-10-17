import 'package:flutter/material.dart';

enum AppSpinnerSize {
  small(16, 2),
  medium(24, 2.5),
  large(36, 3.5);

  const AppSpinnerSize(this.dimension, this.stroke);
  final double dimension;
  final double stroke;
}

class AppSpinner extends StatelessWidget {
  const AppSpinner({
    this.size = AppSpinnerSize.medium,
    this.color,
    this.value,
    super.key,
  });

  final AppSpinnerSize size;

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
