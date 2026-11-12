import 'package:flutter/material.dart';

class AppDurations {
  const AppDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Duration chrome = Duration(
    milliseconds: FadeForwardsPageTransitionsBuilder.kTransitionMilliseconds,
  );

  static const Curve chromeCurve = Curves.fastOutSlowIn;
}

/// THE motion of arriving and leaving (owner 2026-11-12): every page that
/// comes up — a push, a tab's first page — and every back, in a tab or across
/// tabs, and every sheet use these and nothing else. Change a value here and
/// they all change. Dialogs and popup menus keep Flutter's own.
///
/// Entering: the page slides in from the right, fading in, starting 80 % of
/// the way to where it lands (100 % = landed, 0 = off the right edge).
/// Leaving (a back): the page slides off to the right, the page under it held
/// in place. Both run [duration] through [curve] — fast off the mark, a soft
/// landing.
class AppMotion {
  const AppMotion._();

  static const Duration duration = Duration(milliseconds: 150);

  static const Curve curve = Curves.easeOutQuart;

  /// How far a page still has to go when it starts sliding in, a fraction of
  /// its width from where it lands.
  static const double slideFrom = 0.2;

  /// The page's shift at [t] (0 → 1, already through [curve]) while it
  /// enters, a fraction of its width, to the right of where it lands.
  static double enterShift(double t) => slideFrom * (1 - t);

  /// The page's opacity at [t] (0 → 1, through [curve]) while it enters.
  static double enterOpacity(double t) => t;

  /// The curve a closing sheet runs its (reversed) animation through: the
  /// flip of [curve], so it also leaves fast first.
  static final Curve reverseCurve = curve.flipped;

  /// The `sheetAnimationStyle` of a bottom sheet.
  static final AnimationStyle sheetStyle = AnimationStyle(
    duration: duration,
    reverseDuration: duration,
    curve: curve,
    reverseCurve: reverseCurve,
  );
}
