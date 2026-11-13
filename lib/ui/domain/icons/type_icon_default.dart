import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';

/// The icon + colour an item of a given type (a wallet's cash / bank …) shows
/// until the user picks their own; a null [PpForgeIconCode] means "not picked".
class TypeIconDefault {
  const TypeIconDefault({required this.iconId, required this.color});

  /// An [PpForgeIconRegistry] id, so the default can also be an [PpForgeIconCode].
  final String iconId;
  final Color color;

  IconData get icon => PpForgeIconRegistry.get(iconId);

  /// A white glyph on a solid disc in [color].
  PpForgeIconCode get iconCode => PpForgeIconCode(
    icon: iconId,
    iconColors: const ['#FFFFFF'],
    background: 'solid',
    bgColors: [_hex(color)],
  );

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

extension IconCodeTypeDefault on PpForgeIconCode? {
  /// The user's own code, or the type's default when none is picked.
  PpForgeIconCode orDefault(TypeIconDefault d) => this ?? d.iconCode;

  /// The glyph to show: the user's own icon, else the type's.
  IconData glyphOr(TypeIconDefault d) =>
      PpForgeIconRegistry.get(this?.icon, fallback: d.icon);

  /// The colour to tint with: the user's own colour, else the type's.
  Color tintOr(TypeIconDefault d, PpForgeColors palette) =>
      tintFor(palette, fallback: d.color);
}
