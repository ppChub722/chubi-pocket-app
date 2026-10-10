import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../icon_maker/icon_code.dart';
import '../user_avatar.dart';

/// Who a person is to me — the three looks of a person everywhere (owner
/// 2026-10-11: splits, debts, contact picker rows).
enum PersonLevel {
  /// A name typed in, no contact: the generic person icon.
  name,

  /// One of my contacts, not linked to an app account: the contact's own
  /// icon / avatar.
  contact,

  /// A contact linked to an app user: the icon that user set (the
  /// contact's effective icon) + the 🔗 mark.
  linked,
}

/// The one 🔗 "linked to an app account" mark: the link icon in primary,
/// one fixed size whatever the avatar beside it (owner 2026-10-11).
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

/// A person's leading mark at [level] — `👤` · `(avatar)` · `(avatar)🔗`.
/// The 🔗 is [PersonLinkBadge], right after the avatar at its fixed size —
/// "(ม)🔗 มาตาก" — on chips, rows and headers alike.
///
/// [reserveLinkSlot]: in a list of people, unlinked marks keep the 🔗's
/// space empty so every name starts at the same x (owner 2026-10-11). Off
/// for a mark standing alone (a chip — it would only widen it).
class PersonMark extends StatelessWidget {
  const PersonMark({
    required this.name,
    required this.level,
    this.iconCode,
    this.size = 20,
    this.reserveLinkSlot = false,
    super.key,
  });

  /// The 🔗's footprint after a [size] mark: gap + [PersonLinkBadge] — what
  /// [reserveLinkSlot] keeps empty. For a row that builds its own mark (a
  /// typed name's 👤 in an avatar-wide box).
  static double linkSlotWidth(double size) =>
      _gap(size) + PersonLinkBadge.defaultSize;

  static double _gap(double size) => size >= 32 ? 4 : 2;

  final String name;
  final PersonLevel level;

  /// The contact's (linked: the user's) icon; unused for [PersonLevel.name].
  final IconCode? iconCode;
  final double size;
  final bool reserveLinkSlot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget mark = level == PersonLevel.name
        ? Icon(AppIcons.profile, size: size, color: scheme.onSurfaceVariant)
        : UserAvatar(
            displayName: name.isEmpty ? '?' : name,
            iconCode: iconCode,
            size: size,
          );
    if (level == PersonLevel.linked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: _gap(size)),
          const PersonLinkBadge(),
        ],
      );
    }
    if (!reserveLinkSlot) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: linkSlotWidth(size)),
      ],
    );
  }
}
