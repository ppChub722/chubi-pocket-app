import 'package:flutter/painting.dart';

import '../../l10n/gen/app_localizations.dart';

/// Outline of an icon's background (and the border that follows it).
/// Stored as `IconCode.shape` by [name]; `null` / unknown = [circle], so
/// every icon saved before shapes existed keeps rendering as a circle.
enum IconShape {
  circle,
  squircle,
  rounded,
  square,
  leaf,
  drop;

  /// Parses a stored id; anything unknown falls back to [circle].
  static IconShape fromId(String? id) =>
      values.firstWhere((s) => s.name == id, orElse: () => circle);

  /// Corner radii for a [size]×[size] box.
  BorderRadius radius(double size) {
    Radius r(double f) => Radius.circular(size * f);
    return switch (this) {
      IconShape.circle => BorderRadius.all(r(0.5)),
      IconShape.squircle => BorderRadius.all(r(0.32)),
      IconShape.rounded => BorderRadius.all(r(0.2)),
      IconShape.square => BorderRadius.all(r(0.06)),
      IconShape.leaf => BorderRadius.only(
        topLeft: r(0.5),
        topRight: r(0.08),
        bottomRight: r(0.5),
        bottomLeft: r(0.08),
      ),
      IconShape.drop => BorderRadius.only(
        topLeft: r(0.5),
        topRight: r(0.5),
        bottomRight: r(0.5),
        bottomLeft: r(0.08),
      ),
    };
  }

  String label(AppLocalizations l) => switch (this) {
    IconShape.circle => l.iconShapeCircle,
    IconShape.squircle => l.iconShapeSquircle,
    IconShape.rounded => l.iconShapeRounded,
    IconShape.square => l.iconShapeSquare,
    IconShape.leaf => l.iconShapeLeaf,
    IconShape.drop => l.iconShapeDrop,
  };
}
