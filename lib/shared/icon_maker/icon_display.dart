import 'package:flutter/material.dart';

import 'icon_code.dart';
import 'icon_code_widget.dart';
import 'icon_type.dart';

/// Universal icon display widget used on every screen.
///
/// Resolution order:
///   1. [imageUrl] set → NetworkImage (with [_iconWidget] as error fallback)
///   2. [iconCode] set → [IconCodeWidget] (self-inferring style)
///   3. Neither set   → theme-derived default circle for [type]
///
/// Only [account] and [userProfile] types will ever have an [imageUrl] in
/// practice; other types always fall through to step 2 or 3.
class IconDisplay extends StatelessWidget {
  const IconDisplay({
    required this.type,
    required this.size,
    this.imageUrl,
    this.iconCode,
    super.key,
  });

  final IconType type;
  final double size;
  final String? imageUrl;
  final IconCode? iconCode;

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
      // Apply per-type display rules — tag strips bg + border at render time
      // even though the saved code keeps them.
      return IconCodeWidget(
        iconCode: type.applyDisplayRules(iconCode!),
        size: size,
        fallbackIcon: type.fallbackIcon,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        type.fallbackIcon,
        size: size * 0.55,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
