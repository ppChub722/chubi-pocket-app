import 'package:flutter/material.dart';

/// [c] nudged toward black (on a light [against]) or white (on a dark one)
/// until it has at least [min]:1 contrast with [against] — so a pale entity
/// colour still draws a visible border / glyph. Colours that already pass are
/// returned unchanged. Internal to the kit (not exported through ui.dart).
Color ensureContrast(Color c, Color against, {double min = 3}) {
  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  if (ratio(c, against) >= min) return c;
  final target = against.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  for (var t = 0.05; t <= 1; t += 0.05) {
    final next = Color.lerp(c, target, t)!;
    if (ratio(next, against) >= min) return next;
  }
  return target;
}
