import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';
import '../icons/icon_display.dart';
import '../icons/icon_type.dart';

/// An institution's mark (0.4.3): its own icon, else its short name or
/// initials on [color] (the provider's colour) in a rounded square, so it
/// never reads as a person's round avatar.
class InstitutionMark extends StatelessWidget {
  const InstitutionMark({
    required this.name,
    this.iconCode,
    this.shortName,
    this.color,
    this.size = 40,
    super.key,
  });

  final String name;
  final PpForgeIconCode? iconCode;
  final String? shortName;
  final Color? color;
  final double size;

  String get _letters {
    final s = shortName?.trim() ?? '';
    if (s.isNotEmpty) return s.length > 4 ? s.substring(0, 4) : s;
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = words.map((w) => w.characters.first).take(3).join();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }

  /// "#RRGGBB" → a colour; null when it isn't one.
  static Color? parseHex(String? hex) {
    final h = hex?.replaceFirst('#', '').trim() ?? '';
    if (h.length != 6) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

  @override
  Widget build(BuildContext context) {
    final code = iconCode;
    if (code != null) {
      return IconDisplay(type: IconType.category, size: size, iconCode: code);
    }
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.secondaryContainer;
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final letters = _letters;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: FittedBox(
          child: Text(
            letters,
            maxLines: 1,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: size * (letters.length > 2 ? 0.3 : 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
