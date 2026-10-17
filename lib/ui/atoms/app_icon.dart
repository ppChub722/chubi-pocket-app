import 'package:flutter/material.dart';

import '../tokens/icon_size.dart';

/// The one icon: a glyph at an [AppIconSize] step, in the surrounding icon
/// colour unless [color] is given (a theme token, never a literal).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    this.size,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;

  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
}
