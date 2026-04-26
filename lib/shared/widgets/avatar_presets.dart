import 'package:flutter/material.dart';

/// Avatar preset registry — Phase 0 placeholders.
///
/// Each preset has a stable [id] (used in the `preset:<id>:<color>` format
/// stored server-side in `users.avatar_url`) and one of two render sources:
///
/// 1. **[assetPath]** — bundled PNG asset, takes precedence when set. Drop
///    the file in `assets/avatars/`, register the directory in `pubspec.yaml`
///    (`assets: [assets/avatars/]`), and set `assetPath:` on the entry below.
///    See `assets/avatars/README.md` for the asset spec.
/// 2. **[icon]** — Material Icon fallback used while [assetPath] is null.
///
/// Adding a sellable / premium icon later: set [isPremium] = true and [sku]
/// to the store SKU; the picker will show a lock badge until ownership is
/// granted by the entitlements layer (TBD — Phase 2/3).
///
/// `id` strings are **stable** — user selections survive a Material-Icon →
/// PNG → designer-SVG migration as long as the id stays the same.
class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.label,
    required this.icon,
    this.assetPath,
    this.isPremium = false,
    this.sku,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Bundled PNG (or any AssetImage). Wins over [icon] when non-null.
  final String? assetPath;

  /// Marked `true` for sellable icons; rendered with a lock badge in the
  /// picker until the entitlements layer reports ownership.
  final bool isPremium;

  /// Store SKU for the in-app-purchase / Stripe product id.
  final String? sku;

  static const initials = AvatarPreset(
    id: 'initials',
    label: 'Initials',
    icon: Icons.text_fields, // not used at render time — initials drawn instead
  );

  static const male = AvatarPreset(
    id: 'male',
    label: 'Male',
    icon: Icons.man,
    // assetPath: 'assets/avatars/male.png',  // ← uncomment when PNG is added
  );

  static const female = AvatarPreset(
    id: 'female',
    label: 'Female',
    icon: Icons.woman,
    // assetPath: 'assets/avatars/female.png',
  );

  static const chubby = AvatarPreset(
    id: 'chubby',
    label: 'Chubby',
    icon: Icons.sentiment_very_satisfied,
    // assetPath: 'assets/avatars/chubby.png',
  );

  static const snacker = AvatarPreset(
    id: 'snacker',
    label: 'Snacker',
    icon: Icons.bakery_dining,
    // assetPath: 'assets/avatars/snacker.png',
  );

  static const strong = AvatarPreset(
    id: 'strong',
    label: 'Strong',
    icon: Icons.fitness_center,
    // assetPath: 'assets/avatars/strong.png',
  );

  /// Order = order shown in the picker.
  static const List<AvatarPreset> all = [
    initials,
    male,
    female,
    chubby,
    snacker,
    strong,
  ];

  static AvatarPreset byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => initials);
}

/// Color variants the user can pair with any preset.
///
/// [isPremium] / [sku] mirror [AvatarPreset] so paid color packs are possible
/// without further model changes.
class AvatarColor {
  const AvatarColor({
    required this.id,
    required this.label,
    required this.color,
    this.isPremium = false,
    this.sku,
  });

  final String id;
  final String label;
  final Color color;
  final bool isPremium;
  final String? sku;

  static const red = AvatarColor(
    id: 'red',
    label: 'Red',
    color: Color(0xFFE57373),
  );
  static const green = AvatarColor(
    id: 'green',
    label: 'Green',
    color: Color(0xFF81C784),
  );
  static const blue = AvatarColor(
    id: 'blue',
    label: 'Blue',
    color: Color(0xFF64B5F6),
  );
  static const teal = AvatarColor(
    id: 'teal',
    label: 'Teal',
    color: Color(0xFF00A389), // brand color
  );
  static const pink = AvatarColor(
    id: 'pink',
    label: 'Pink',
    color: Color(0xFFF06292),
  );

  static const List<AvatarColor> all = [red, green, blue, teal, pink];

  static AvatarColor byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => teal);
}

/// Parsed `preset:<icon>:<color>` value. Returns null when [raw] is not a
/// preset string (e.g. an http URL, or null).
class AvatarPresetSelection {
  const AvatarPresetSelection({required this.preset, required this.color});

  final AvatarPreset preset;
  final AvatarColor color;

  static const String _scheme = 'preset:';

  /// Default selection used when the user opens the picker with no current
  /// preset stored.
  static const AvatarPresetSelection defaultSelection = AvatarPresetSelection(
    preset: AvatarPreset.initials,
    color: AvatarColor.teal,
  );

  static AvatarPresetSelection? tryParse(String? raw) {
    if (raw == null || !raw.startsWith(_scheme)) return null;
    final parts = raw.substring(_scheme.length).split(':');
    if (parts.length != 2) return null;
    return AvatarPresetSelection(
      preset: AvatarPreset.byId(parts[0]),
      color: AvatarColor.byId(parts[1]),
    );
  }

  /// Serialised form to store in `users.avatar_url`.
  String encode() => '$_scheme${preset.id}:${color.id}';

  AvatarPresetSelection copyWith({AvatarPreset? preset, AvatarColor? color}) {
    return AvatarPresetSelection(
      preset: preset ?? this.preset,
      color: color ?? this.color,
    );
  }
}
