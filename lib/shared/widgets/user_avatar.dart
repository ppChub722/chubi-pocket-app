import 'package:flutter/material.dart';

import 'avatar_presets.dart';

/// Circular avatar.
///
/// Resolution order based on [avatarUrl]:
/// 1. `preset:<icon>:<color>` → render the icon (or initials) over the colour.
/// 2. `http(s)://...` → load image; on failure fall back to initials.
/// 3. null / empty → letter-initials fallback, name-hashed colour from §3.4.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.size = 40,
  });

  final String displayName;
  final String? avatarUrl;
  final double size;

  /// 12-color palette from design-sheet §3.4 — used only for the no-preset,
  /// no-URL initials fallback.
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
    final preset = AvatarPresetSelection.tryParse(avatarUrl);
    if (preset != null) return _buildPreset(context, preset);

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildInitialsHashed(context),
        ),
      );
    }

    return _buildInitialsHashed(context);
  }

  /// Initials variant used when no preset is stored — colour is hashed from
  /// the name so the same person always gets the same colour.
  Widget _buildInitialsHashed(BuildContext context) {
    final initials = _initialsOf(displayName);
    if (initials.isEmpty) return _buildGenericIcon(context);
    return _circleAvatar(_colorFor(displayName), Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.42,
        fontWeight: FontWeight.w600,
      ),
    ));
  }

  Widget _buildPreset(BuildContext context, AvatarPresetSelection sel) {
    if (sel.preset.id == AvatarPreset.initials.id) {
      final initials = _initialsOf(displayName);
      return _circleAvatar(
        sel.color.color,
        initials.isEmpty
            ? Icon(Icons.person, size: size * 0.55, color: Colors.white)
            : Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }

    // Bundled PNG takes precedence; falls back to the Material Icon when the
    // asset is missing (handy while assets are being onboarded one at a time).
    final assetPath = sel.preset.assetPath;
    if (assetPath != null) {
      return _circleAvatar(
        sel.color.color,
        Image.asset(
          assetPath,
          width: size * 0.7,
          height: size * 0.7,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            sel.preset.icon,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      );
    }
    return _circleAvatar(
      sel.color.color,
      Icon(sel.preset.icon, size: size * 0.55, color: Colors.white),
    );
  }

  Widget _buildGenericIcon(BuildContext context) {
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

  Widget _circleAvatar(Color background, Widget child) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: background,
      child: child,
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
