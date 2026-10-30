import 'package:flutter/material.dart';

import '../../atoms/editable_circle.dart';
import '../../molecules/hero_style.dart';
import '../../organisms/hero/app_hero_card.dart';
import '../../organisms/hero/hero_facts.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import 'avatar.dart';
import 'avatar_data.dart';
import 'profile_color_dots.dart';

/// The profile hero's picture (0.4.2 1b): the [Avatar] at [size] with, in
/// view mode, the source app's logo as a corner [badge]; in edit mode a ✎
/// badge and a tap (the icon maker). Under it the profile colours 1–3
/// ([ProfileColorDots]).
class ProfileHeroAvatar extends StatelessWidget {
  const ProfileHeroAvatar({
    required this.avatar,
    this.size = 56,
    this.badge,
    this.editing = false,
    this.onTap,
    this.onLongPress,
    this.dotsLabel,
    super.key,
  });

  final AvatarData avatar;
  final double size;

  /// View mode: the logo of the app the picture comes from.
  final Widget? badge;

  /// Edit mode: the ✎ badge (with [onTap]) in place of [badge].
  final bool editing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? dotsLabel;

  @override
  Widget build(BuildContext context) {
    final picture = editing
        ? EditableCircle(
            size: size,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Avatar(avatar, size: size),
          )
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Avatar(
              avatar,
              size: size,
              badge: badge,
              badgeColor: Theme.of(context).colorScheme.surface,
              badgeEssential: true,
            ),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        picture,
        const SizedBox(height: AppSpacing.sm),
        ProfileColorDots(colors: avatar.colors, semanticLabel: dotsLabel),
      ],
    );
  }
}

/// The profile page's hero (0.4.2 1b, like the contact page): tinted with
/// colour 1. View: [picture] · the name (big) over [handle] · [actions] (✏️)
/// at the end, then [facts] (the email row). Edit: [picture] beside the
/// [fields] (labelled underline inputs).
class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    required this.tint,
    required this.picture,
    this.name,
    this.handle,
    this.actions = const [],
    this.facts = const [],
    this.fields = const [],
    this.editing = false,
    this.onLongPress,
    super.key,
  });

  /// Colour 1 (ProfileColors.main): the card's border and wash.
  final Color tint;

  /// A [ProfileHeroAvatar].
  final Widget picture;
  final String? name;

  /// `@username`.
  final String? handle;
  final List<Widget> actions;
  final List<HeroFact> facts;

  /// Edit mode: the inputs beside the picture, top to bottom.
  final List<Widget> fields;
  final bool editing;

  /// View mode: long-press anywhere on the card (enter edit).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final style = HeroStyle.tinted(color: tint, glyph: AppIcons.profile);
    if (editing) {
      return AppHeroCard(
        style: style,
        mode: HeroCardMode.edit,
        content: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              picture,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, f) in fields.indexed) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      f,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: AppHeroCard(
        style: style,
        content: [
          _ViewIdentity(
            picture: picture,
            name: name,
            handle: handle,
            actions: actions,
          ),
          if (facts.isNotEmpty) HeroFactList(facts: facts),
        ],
      ),
    );
  }
}

class _ViewIdentity extends StatelessWidget {
  const _ViewIdentity({
    required this.picture,
    required this.name,
    required this.handle,
    required this.actions,
  });

  final Widget picture;
  final String? name;
  final String? handle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted =
        HeroColors.maybeOf(context)?.muted ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        picture,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name != null)
                  Text(
                    name!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (handle != null)
                  Text(
                    handle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: AppSpacing.sm), a],
      ],
    );
  }
}
