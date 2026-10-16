import 'package:flutter/material.dart';

import 'icon_code.dart';
import 'packs/icon_pack.dart';

/// What an icon belongs to — the host app declares one per thing that has an
/// icon (an account, a category, …) and passes it to [IconDisplay] and
/// `showIconMakerSheet`. It decides:
/// - [fallbackIcon]: drawn when the thing has no icon code,
/// - [basePack]: what the icon maker offers (null = display-only, no picker),
/// - [iconOnly]: render just the tinted glyph — no background / border.
@immutable
class PpForgeIconType {
  const PpForgeIconType(
    this.id, {
    required this.fallbackIcon,
    this.basePack,
    this.iconOnly = false,
  });

  /// Stable, app-chosen name (for debugging / keys).
  final String id;
  final IconData fallbackIcon;
  final IconPack? basePack;

  /// Tag-style icons: background + border are kept in the saved code but
  /// never drawn ([applyDisplayRules]), and the maker's preview hides them.
  final bool iconOnly;

  /// Whether this type has an icon maker.
  bool get hasPicker => basePack != null;

  /// Strips the layers this type ignores at render time.
  IconCode applyDisplayRules(IconCode code) =>
      iconOnly ? IconCode(icon: code.icon, iconColors: code.iconColors) : code;

  /// The maker preview's default hide-toggles. The user can override them
  /// per session; they control only the live preview, never the saved code.
  ({bool icon, bool bg, bool border}) get defaultPreviewHides =>
      (icon: false, bg: iconOnly, border: iconOnly);

  @override
  String toString() => 'PpForgeIconType($id)';
}
