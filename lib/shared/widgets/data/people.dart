import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../icon_maker/icon_code.dart';
import '../layout/add_tile.dart';
import '../user_avatar.dart';

/// Minimal person shape for avatar widgets — map wallet members, project
/// members, contacts into this so one widget serves them all.
class PersonRef {
  const PersonRef({
    required this.name,
    this.iconCode,
    this.caption,
    this.isOwner = false,
    this.pending = false,
  });

  final String name;
  final IconCode? iconCode;

  /// Under-name line in [MemberStrip] ("คุณ", "รอตอบรับ").
  final String? caption;
  final bool isOwner;

  /// Renders faded (invited, not yet joined).
  final bool pending;
}

/// Overlapping avatar stack with a "+N" overflow bubble.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.people,
    this.size = 28,
    this.maxVisible = 4,
    super.key,
  });

  final List<PersonRef> people;
  final double size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final visible = people.take(maxVisible).toList();
    final overflow = people.length - visible.length;
    final step = size * 0.7;
    final count = visible.length + (overflow > 0 ? 1 : 0);
    final width = (count - 1) * step + size;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * step,
              child: Tooltip(
                message: visible[i].name,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 1.5),
                  ),
                  child: UserAvatar(
                    displayName: visible[i].name,
                    iconCode: visible[i].iconCode,
                    size: size,
                  ),
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * step,
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling member row: avatar + name (+ caption) per person,
/// 👑 for the owner, faded pending members, and a dashed "+ เชิญ" circle at
/// the end when [onInvite] is set.
class MemberStrip extends StatelessWidget {
  const MemberStrip({
    required this.members,
    this.onMemberTap,
    this.onInvite,
    this.inviteLabel,
    this.avatarSize = 48,
    super.key,
  });

  final List<PersonRef> members;
  final ValueChanged<int>? onMemberTap;
  final VoidCallback? onInvite;

  /// Defaults to the localized "เชิญ".
  final String? inviteLabel;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final itemWidth = avatarSize + AppSpacing.lg;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < members.length; i++)
            InkWell(
              onTap: onMemberTap == null ? null : () => onMemberTap!(i),
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: members[i].pending ? 0.5 : 1,
                child: SizedBox(
                  width: itemWidth,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UserAvatar(
                          displayName: members[i].name,
                          iconCode: members[i].iconCode,
                          size: avatarSize,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          members[i].isOwner
                              ? '${members[i].name} 👑'
                              : members[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium,
                        ),
                        if (members[i].caption != null)
                          Text(
                            members[i].caption!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (onInvite != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: AddTile(
                label: inviteLabel ?? AppLocalizations.of(context)!.commonInvite,
                onTap: onInvite,
                variant: AddTileVariant.circle,
                circleSize: avatarSize,
              ),
            ),
        ],
      ),
    );
  }
}
