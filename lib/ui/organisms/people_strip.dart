import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/dashed_rect_border.dart';
import '../molecules/detail_rows.dart';
import '../tokens/app/app_colors.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// The colour of a [PeopleStripMember.caption].
enum PeopleTone { neutral, positive, negative }

/// One member card of a [PeopleStrip].
class PeopleStripMember {
  const PeopleStripMember({
    required this.avatar,
    required this.name,
    this.lead,
    this.caption,
    this.tone = PeopleTone.neutral,
  });

  final Widget avatar;
  final String name;

  /// A muted line above [caption] ("paid 120"); never toned.
  final String? lead;

  /// e.g. "owes 120" / "is owed 80".
  final String? caption;
  final PeopleTone tone;
}

/// A headed, horizontally scrolling strip of member cards with a dashed
/// "+ invite" card at the end. Shared by events and wallets.
class PeopleStrip extends StatelessWidget {
  const PeopleStrip({
    required this.title,
    required this.members,
    required this.onInvite,
    required this.inviteLabel,
    this.description,
    this.onMemberTap,
    this.actionLabel,
    this.onAction,
    this.first = false,
    super.key,
  });

  final String title;
  final String? description;

  /// A text action at the end of the title row ("Manage ›"); null = none.
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<PeopleStripMember> members;

  /// Null = no invite card.
  final VoidCallback? onInvite;
  final String inviteLabel;
  final ValueChanged<int>? onMemberTap;
  final bool first;

  static const _cardWidth = 104.0;
  static const _cardHeight = 128.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          first: first,
          title: title,
          description: description,
          trailing: actionLabel == null || onAction == null
              ? null
              : AppButton(
                  label: actionLabel!,
                  variant: AppButtonVariant.text,
                  onPressed: onAction,
                ),
          children: const [],
        ),
        SizedBox(
          height: _cardHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (i, m) in members.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                _MemberCard(
                  member: m,
                  onTap: onMemberTap == null ? null : () => onMemberTap!(i),
                ),
              ],
              if (onInvite != null) ...[
                if (members.isNotEmpty) const SizedBox(width: AppSpacing.sm),
                _InviteCard(label: inviteLabel, onTap: onInvite!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});

  final PeopleStripMember member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<AppColors>();
    final tone = switch (member.tone) {
      PeopleTone.neutral => scheme.onSurfaceVariant,
      PeopleTone.positive => colors?.income ?? scheme.primary,
      PeopleTone.negative => colors?.expense ?? scheme.error,
    };
    return SizedBox(
      width: PeopleStrip._cardWidth,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                member.avatar,
                const SizedBox(height: AppSpacing.xs),
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge,
                ),
                if (member.lead != null)
                  Text(
                    member.lead!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (member.caption != null)
                  Text(
                    member.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: tone),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: PeopleStrip._cardWidth,
      child: DashedRectBorder(
        color: color,
        borderRadius: const Radius.circular(AppRadius.lg),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.add, color: color),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
