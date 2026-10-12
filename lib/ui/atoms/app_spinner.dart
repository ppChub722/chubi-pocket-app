import 'package:flutter/material.dart';

/// The spinner sizes: inside a button / chip ([small]), inline next to text
/// ([medium]), a page or overlay ([large]).
enum AppSpinnerSize {
  small(16, 2),
  medium(24, 2.5),
  large(36, 3.5);

  const AppSpinnerSize(this.dimension, this.stroke);
  final double dimension;
  final double stroke;
}

/// The one spinner (owner 2026-10-12): a circle in a fixed box. Features never
/// size a `CircularProgressIndicator` by hand. Skeletons are for first loads;
/// the spinner is for a call in flight (save, delete) — see `SavingOverlay`.
class AppSpinner extends StatelessWidget {
  const AppSpinner({
    this.size = AppSpinnerSize.medium,
    this.color,
    this.value,
    super.key,
  });

  final AppSpinnerSize size;

  /// Defaults to the theme's primary colour.
  final Color? color;

  /// Null = indeterminate; 0–1 = determinate.
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
