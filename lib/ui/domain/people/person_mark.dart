import 'package:flutter/material.dart';

import '../../tokens/app/app_icons.dart';
import '../icons/icon_code.dart';
import '../../atoms/user_avatar.dart';

enum PersonLevel { name, contact, linked }

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
    this.size = 20,
    this.reserveLinkSlot = false,
    super.key,
  });

  static double linkSlotWidth(double size) =>
      _gap(size) + PersonLinkBadge.defaultSize;

  static double _gap(double size) => size >= 32 ? 4 : 2;

  final String name;
  final PersonLevel level;

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
