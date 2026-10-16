import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';
import 'user_avatar.dart';

/// Compact user preview row: `[ avatar ] displayName`.
class UserProfilePreview extends StatelessWidget {
  const UserProfilePreview({
    required this.displayName,
    this.iconCode,
    this.size = 56,
    super.key,
  });

  final String displayName;
  final IconCode? iconCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PpForgeSpacing.md,
        vertical: PpForgeSpacing.sm,
      ),
      child: Row(
        children: [
          UserAvatar(displayName: displayName, iconCode: iconCode, size: size),
          const SizedBox(width: PpForgeSpacing.lg),
          Expanded(
            child: Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
