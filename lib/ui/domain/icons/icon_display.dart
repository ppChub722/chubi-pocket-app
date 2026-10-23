import 'package:flutter/material.dart';

import '../../tokens/avatar_metrics.dart';
import 'icon_code.dart';
import 'icon_code_widget.dart';
import 'icon_type.dart';

class IconDisplay extends StatelessWidget {
  const IconDisplay({
    required this.type,
    required this.size,
    this.imageUrl,
    this.iconCode,
    this.fallbackColor,
    super.key,
  });

  final IconType type;
  final double size;
  final String? imageUrl;
  final IconCode? iconCode;

  /// No [iconCode]: the default disc in this colour (a wallet passes the
  /// colour its card falls back to, so icon and card match; owner
  /// 2026-10-23). Null = the theme's primary container.
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _iconWidget(context),
        ),
      );
    }
    return _iconWidget(context);
  }

  Widget _iconWidget(BuildContext context) {
    if (iconCode != null) {
      return IconCodeWidget(
        iconCode: type.applyDisplayRules(iconCode!),
        size: size,
        fallbackIcon: type.fallbackIcon,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    // A tag never has a disc (see applyDisplayRules): no code → the bare glyph
    // in the primary colour, like a tag with an icon.
    if (type == IconType.tag) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            type.fallbackIcon,
            size: AvatarMetrics.glyph(size) * 1.12,
            color: scheme.primary,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackColor ?? scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        type.fallbackIcon,
        size: size * 0.55,
        color: fallbackColor == null ? scheme.onPrimaryContainer : Colors.white,
      ),
    );
  }
}
