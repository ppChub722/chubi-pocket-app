import 'package:flutter/material.dart';

import '../tokens/avatar_metrics.dart';

/// The one round avatar: initials on a name-hashed colour, a tinted initial,
/// a glyph, or a custom label (the "+3" overflow of a stack). Features never
/// build a `CircleAvatar`.
///
/// ```dart
/// AppAvatar(name: 'Aom Chan')                         // "AC" on a hashed colour
/// AppAvatar.tinted(name: 'Bee', color: c, size: 28)    // soft tint, coloured B
/// AppAvatar.icon(AppIcons.person, size: 40)            // a glyph on a neutral disc
/// AppAvatar.label('+3', size: 32)                      // neutral disc, text
/// ```
class AppAvatar extends StatelessWidget {
  /// Initials (first letters of the first two words) in white on a colour
  /// hashed from [name]. An empty name falls back to a neutral person glyph.
  const AppAvatar({required this.name, this.size = 40, super.key})
    : _mode = _Mode.initials,
      _glyph = null,
      _color = null,
      _text = null;

  /// The first letter of [name] in [color], on a 28% tint of it.
  const AppAvatar.tinted({
    required this.name,
    required Color color,
    this.size = 40,
    super.key,
  }) : _mode = _Mode.tinted,
       _glyph = null,
       _color = color,
       _text = null;

  /// A glyph on a neutral disc.
  const AppAvatar.icon(IconData glyph, {this.size = 40, super.key})
    : name = '',
      _mode = _Mode.glyph,
      _glyph = glyph,
      _color = null,
      _text = null;

  /// Any short text (a "+3" overflow count) on a neutral disc.
  const AppAvatar.label(String text, {this.size = 40, super.key})
    : name = '',
      _mode = _Mode.label,
      _glyph = null,
      _color = null,
      _text = text;

  final String name;
  final double size;
  final _Mode _mode;
  final IconData? _glyph;
  final Color? _color;
  final String? _text;

  /// 12-colour palette (design-sheet §3.4) for the initials fallback.
  static const List<Color> hashPalette = [
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
    final scheme = Theme.of(context).colorScheme;
    switch (_mode) {
      case _Mode.initials:
        final initials = _initialsOf(name);
        if (initials.isEmpty) {
          return _disc(
            scheme.surfaceContainerHighest,
            Icon(
              Icons.person_outline,
              size: AvatarMetrics.glyph(size),
              color: scheme.onSurfaceVariant,
            ),
          );
        }
        return _disc(
          _colorFor(name),
          Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: AvatarMetrics.initials(size),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case _Mode.tinted:
        return _disc(
          _color!.withValues(alpha: 0.28),
          Text(
            name.trim().isEmpty
                ? '?'
                : name.trim().characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: AvatarMetrics.initials(size),
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case _Mode.glyph:
        return _disc(
          scheme.surfaceContainerHighest,
          Icon(
            _glyph,
            size: AvatarMetrics.glyph(size),
            color: scheme.onSurface,
          ),
        );
      case _Mode.label:
        return _disc(
          scheme.surfaceContainerHighest,
          Padding(
            padding: const EdgeInsets.all(2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _text!,
                style: TextStyle(
                  fontSize: AvatarMetrics.initials(size),
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _disc(Color background, Widget child) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: child,
  );

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

  /// The colour [name]'s initials avatar is drawn on (a soft tint of it backs a
  /// person's name in a split row).
  static Color colorFor(String name) => _colorFor(name);

  static Color _colorFor(String name) {
    if (name.isEmpty) return hashPalette.first;
    var hash = 0;
    for (final r in name.runes) {
      hash = (hash * 31 + r) & 0x7fffffff;
    }
    return hashPalette[hash % hashPalette.length];
  }
}

enum _Mode { initials, tinted, glyph, label }
