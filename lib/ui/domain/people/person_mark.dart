import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../icons/icon_code.dart';
import '../../atoms/corner_badge.dart';
import '../../atoms/dashed_rect_border.dart';
import 'avatar.dart';
import 'avatar_data.dart';

/// [empty] = a spot with nobody in it yet (an event member removed: "( ) ____"
/// on their bills, to assign).
enum PersonLevel { name, contact, linked, empty }

class PersonLinkBadge extends StatelessWidget {
  const PersonLinkBadge({this.size = defaultSize, super.key});

  static const double defaultSize = 16;

  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    AppIcons.link,
    size: size,
    color: Theme.of(context).colorScheme.primary,
  );
}

class PersonMark extends StatelessWidget {
  const PersonMark({
    required this.name,
    required this.level,
    this.iconCode,
    this.avatar,
    this.size = 20,
    this.reserveLinkSlot = false,
    this.tappable = false,
    this.linkOnCorner = false,
    super.key,
  });

  /// Kept for callers: a linked person's 🔗 is now ALWAYS a [CornerBadge] on
  /// the avatar (owner 2026-10-23, app-wide).
  final bool linkOnCorner;

  /// The badge sits on the avatar, so no row needs a slot beside it.
  static double linkSlotWidth(double size) => 0;

  final String name;
  final PersonLevel level;

  final IconCode? iconCode;

  /// The BE's avatar (contact / linked levels); null = built from [name] +
  /// [iconCode].
  final AvatarData? avatar;
  final double size;

  /// Kept for callers; no-op now that the badge sits on the avatar.
  final bool reserveLinkSlot;

  /// Draws the name-level icon inside a dashed ring so it reads as pressable.
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (level == PersonLevel.empty) {
      // An empty dashed ring: nobody there yet.
      return SizedBox.square(
        dimension: size,
        child: DashedRectBorder(
          color: scheme.outline,
          strokeWidth: 1.2,
          dashLength: 3,
          gapLength: 3,
          borderRadius: Radius.circular(size / 2),
          child: const SizedBox.expand(),
        ),
      );
    }
    // The outline glyph fills its box edge to edge: a touch smaller so it
    // reads the same size as a round avatar (owner 2026-10-30).
    final Widget plain = SizedBox.square(
      dimension: size,
      child: Center(
        child: Icon(
          AppIcons.profile,
          size: size * 0.85,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    final Widget mark = level == PersonLevel.name
        ? tappable
              ? SizedBox.square(
                  dimension: size,
                  child: DashedRectBorder(
                    color: scheme.primary,
                    strokeWidth: 1.2,
                    dashLength: 4,
                    gapLength: 3,
                    borderRadius: Radius.circular(size / 2),
                    child: Center(
                      child: Icon(
                        AppIcons.profile,
                        size: size * 0.6,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : plain
        : Avatar(
            avatar ??
                AvatarData.forName(
                  name.isEmpty ? '?' : name,
                  iconCode: iconCode,
                ),
            size: size,
          );
    if (level != PersonLevel.linked) return mark;
    // A touch bigger than other corner badges, the chain nearly filling it
    // (owner 2026-10-23).
    return CornerBadge(
      size: size,
      icon: AppIcons.link,
      essential: true,
      scale: 1.15,
      glyphRatio: 0.82,
      child: mark,
    );
  }
}
