import 'package:flutter/material.dart';

import '../domain/icons/icon_code.dart';
import '../domain/icons/icon_display.dart';
import '../domain/icons/icon_type.dart';
import 'app_avatar.dart';

/// A user's avatar: their chosen icon ([iconCode], rendered by the icon
/// maker) or, without one, an [AppAvatar] of their initials.
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
    return AppAvatar(name: displayName, size: size);
  }
}
