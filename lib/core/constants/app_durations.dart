import 'package:flutter/material.dart';

class AppDurations {
  const AppDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  /// Shell chrome motion (top bar, tab switch) — the Android page
  /// transition's length, so a part moving in place (edit mode, a tab
  /// switch) takes exactly as long as one riding a push / back.
  static const Duration chrome = Duration(
    milliseconds: FadeForwardsPageTransitionsBuilder.kTransitionMilliseconds,
  );

  /// Curve for [chrome] — [Hero]'s default, for the same reason.
  static const Curve chromeCurve = Curves.fastOutSlowIn;
}
