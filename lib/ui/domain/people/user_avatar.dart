import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';
import '../icons/icon_type.dart';

/// A user's avatar: their chosen icon ([iconCode], rendered by the icon
/// maker) or, without one, an [PpForgeAvatar] of their initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    this.iconCode,
    this.size = 40,
  });

  final String displayName;
  final IconCode? iconCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconCode != null) {
      return IconDisplay(
        type: IconType.userProfile,
        size: size,
        iconCode: iconCode,
      );
    }
    return PpForgeAvatar(name: displayName, size: size);
  }
}
