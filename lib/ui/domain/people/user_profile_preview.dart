import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../icons/icon_code.dart';
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
  final IconCode? iconCode;

  /// The avatar to show; null = built from [displayName] + [iconCode] (the
  /// icon maker's live preview passes only the icon).
  final AvatarData? avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Avatar(
            avatar ?? AvatarData.forName(displayName, iconCode: iconCode),
            size: size,
          ),
          const SizedBox(width: AppSpacing.lg),
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
