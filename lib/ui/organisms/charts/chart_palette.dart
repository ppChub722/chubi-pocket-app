import 'package:flutter/material.dart';

/// Categorical series colours for charts — a fixed order, assigned by
/// position and never cycled. Past [categorical].length series, fold the
/// rest into "อื่นๆ" and paint it [other].
///
/// Light/dark are separate validated steps of the same hues (CVD-safe on
/// adjacent pairs), not a brightness flip. Series colours mark identity
/// only — labels and amounts stay in text colours, and every chart pairs
/// them with a legend so colour is never the only cue.
class ChartPalette {
  const ChartPalette._();

  static const _light = [
    Color(0xFF2A78D6), // blue
    Color(0xFFEB6834), // orange
    Color(0xFF1BAF7A), // aqua
    Color(0xFFEDA100), // yellow
  ];
  static const _dark = [
    Color(0xFF3987E5),
    Color(0xFFD95926),
    Color(0xFF199E70),
    Color(0xFFC98500),
  ];

  static List<Color> categorical(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Neutral for the folded "อื่นๆ" slice.
  static Color other(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
}
