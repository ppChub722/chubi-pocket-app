import 'package:flutter/material.dart';

import '../icon_maker/icon_code.dart';
import '../icon_maker/icon_display.dart';
import '../icon_maker/icon_type.dart';

/// Circular avatar.
///
/// If [iconCode] is set, renders it as a background-style circle (solid
/// colour + white icon). Otherwise falls back to letter-initials with a
/// name-hashed colour.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    this.iconCode,
    this.size = 40,
  });

  final String displayName;
  final IconCode? iconCode;
  final double size;

  /// 12-color palette from design-sheet §3.4 — used for the initials fallback.
  static const List<Color> _hashPalette = [
    Color(0xFFE57373),
    Color(0xFFF06292),
    Color(0xFFBA68C8),
    Color(0xFF9575CD),
    Color(0xFF7986CB),
    Color(0xFF64B5F6),
    Color(0xFF4FC3F7),
    Color(0xFF4DD0E1),
    Color(0xFFAED581),
    Color(0xFFFFD54F),
    Color(0xFFFFB74D),
    Color(0xFFA1887F),
  ];

  @override
  Widget build(BuildContext context) {
    if (iconCode != null) {
      return IconDisplay(
        type: IconType.userProfile,
        size: size,
        iconCode: iconCode,
      );
    }
    final initials = _initialsOf(displayName);
    if (initials.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outline,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _colorFor(displayName),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '';
    if (words.length == 1) {
      return words.first.characters.take(1).toString().toUpperCase();
    }
    final first = words.first.characters.firstOrNull ?? '';
    final second = words[1].characters.firstOrNull ?? '';
    return '$first$second'.toUpperCase();
  }

  static Color _colorFor(String name) {
    if (name.isEmpty) return _hashPalette.first;
    var hash = 0;
    for (final r in name.runes) {
      hash = (hash * 31 + r) & 0x7fffffff;
    }
    return _hashPalette[hash % _hashPalette.length];
  }
}
