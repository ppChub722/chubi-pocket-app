import 'package:flutter/material.dart';

import '../tokens/icon_size.dart';

/// The one icon: a glyph at an [PpForgeIconSize] step, in the surrounding icon
/// colour unless [color] is given (a theme token, never a literal).
///
/// ```dart
/// PpForgeIcon(PpForgeIcons.lock, size: PpForgeIconSize.sm, color: scheme.onSurfaceVariant)
/// ```
class PpForgeIcon extends StatelessWidget {
  const PpForgeIcon(
    this.icon, {
    this.size,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;

  /// One of the [PpForgeIconSize] steps; null = inherit the surrounding
  /// `IconTheme` (rows and buttons size their icons for you).
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
}
