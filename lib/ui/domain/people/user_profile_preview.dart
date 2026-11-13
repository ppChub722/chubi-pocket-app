import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';
import 'avatar.dart';
import 'avatar_data.dart';

class UserProfilePreview extends StatelessWidget {
  const UserProfilePreview({
    required this.displayName,
    this.iconCode,
    this.avatar,
    this.size = 56,
    super.key,
  });

  final String displayName;
  final PpForgeIconCode? iconCode;

  /// The avatar to show; null = built from [displayName] + [iconCode] (the
  /// icon maker's live preview passes only the icon).
  final AvatarData? avatar;
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
          Avatar(
            avatar ?? AvatarData.forName(displayName, iconCode: iconCode),
            size: size,
          ),
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
