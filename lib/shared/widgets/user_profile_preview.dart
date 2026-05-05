import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../icon_maker/icon_code.dart';
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
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          UserAvatar(
            displayName: displayName,
            iconCode: iconCode,
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
