import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import 'user_avatar.dart';

/// Compact user preview row: `[ avatar ] displayName`.
///
/// Mirrors the `[ icon ] name` layout of `AccountCard` so both contexts
/// read the same way at a glance — once a user has interacted with one,
/// they predict how the other looks. Used as the `previewBuilder` for the
/// avatar picker (and any future flow that wants a compact "this user"
/// header).
class UserProfilePreview extends StatelessWidget {
  const UserProfilePreview({
    required this.displayName,
    required this.avatarUrl,
    this.size = 56,
    super.key,
  });

  final String displayName;
  final String? avatarUrl;

  /// Avatar diameter in dp. Defaults to 56 — matches the picker preview's
  /// visual weight (where the previous design used a 96 dp centered
  /// avatar; the row layout reads better at a slightly smaller size).
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
            avatarUrl: avatarUrl,
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
