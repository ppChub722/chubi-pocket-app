import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../../atoms/app_avatar.dart';
import '../icons/icon_code.dart';

/// What an [AvatarData] draws (the BE decides, the app never picks).
enum AvatarKind {
  /// A stored picture (`photo_url`); on a load error the icon, then initials.
  photo,

  /// The icon maker's icon (`icon_code`, its own colours and border).
  icon,

  /// The initials on colour 1.
  initials;

  static AvatarKind parse(Object? wire) => switch (wire) {
    'photo' => photo,
    'icon' => icon,
    _ => initials,
  };
}

/// The ring around a picture (`avatar.border`): an icon-maker border id
/// ([style]: thin / thick / dashed) and its colours (a theme token or
/// `#rrggbb`). An icon carries its own border inside `icon_code`.
class AvatarBorder extends Equatable {
  const AvatarBorder({required this.style, this.colors = const []});

  factory AvatarBorder.fromJson(Map<String, dynamic> json) => AvatarBorder(
    style: (json['style'] as String?) ?? '',
    colors: _strings(json['colors']),
  );

  /// thin / thick / dashed; '' or 'none' = no ring.
  final String style;
  final List<String> colors;

  bool get isNone => style.isEmpty || style == 'none';

  Map<String, dynamic> toJson() => {'style': style, 'colors': colors};

  @override
  List<Object?> get props => [style, colors];
}

/// How to draw one person (0.4.2 1b, the BE's `avatar` object, the same on
/// every person payload). The kit's `Avatar` draws it.
class AvatarData extends Equatable {
  const AvatarData({
    required this.kind,
    this.photoUrl,
    this.iconCode,
    this.initials = '',
    this.colors = const [],
    this.border,
  });

  factory AvatarData.fromJson(Map<String, dynamic> json) => AvatarData(
    kind: AvatarKind.parse(json['kind']),
    photoUrl: json['photo_url'] as String?,
    iconCode: json['icon_code'] is Map
        ? IconCode.fromJson((json['icon_code'] as Map).cast<String, dynamic>())
        : null,
    initials: (json['initials'] as String?) ?? '',
    colors: _strings(json['colors']),
    border: json['border'] is Map
        ? AvatarBorder.fromJson((json['border'] as Map).cast<String, dynamic>())
        : null,
  );

  /// Built in the app the way the BE builds it, from a name and an optional
  /// icon: hub demos, a typed name not saved yet, a payload cached before
  /// 0.4.2. Colours: the icon's (backgrounds, icons, borders, no repeats),
  /// else the name-hash colour.
  factory AvatarData.forName(String name, {IconCode? iconCode}) {
    final fromIcon = iconCode == null ? const <String>[] : iconColors(iconCode);
    return AvatarData(
      kind: iconCode == null ? AvatarKind.initials : AvatarKind.icon,
      iconCode: iconCode,
      initials: initialsOf(name),
      colors: fromIcon.isNotEmpty ? fromIcon : [nameColorHex(name)],
    );
  }

  /// A person payload's avatar: `json['avatar']`; a payload from before
  /// 0.4.2 (an old cache) has none, so its top-level `icon_code` and [name]
  /// build one.
  static AvatarData parse(Map<String, dynamic> json, {required String name}) {
    final avatar = json['avatar'];
    if (avatar is Map) {
      return AvatarData.fromJson(avatar.cast<String, dynamic>());
    }
    final legacy = json['icon_code'];
    return AvatarData.forName(
      name,
      iconCode: legacy is Map
          ? IconCode.fromJson(legacy.cast<String, dynamic>())
          : null,
    );
  }

  final AvatarKind kind;

  /// kind photo only: `/api/v1/avatars/{id}?v={version}` (a path from the
  /// server root; the `?v=` changes with the picture).
  final String? photoUrl;

  /// The person's icon when they have one (also with a photo: the fallback).
  final IconCode? iconCode;

  /// Up to two letters; '' for an empty name.
  final String initials;

  /// Profile colours in order (colour 1 = the main one; the UI shows 1–3).
  /// A theme token or `#rrggbb`. See `ProfileColors` to pick from them.
  final List<String> colors;

  /// kind photo only: the ring around the picture.
  final AvatarBorder? border;

  bool get hasPhoto =>
      kind == AvatarKind.photo && (photoUrl?.isNotEmpty ?? false);

  /// The same person with [code] as their icon (an icon edit before the
  /// server answers): a photo stays a photo (the icon is its fallback);
  /// otherwise it becomes an icon / initials avatar with the icon's colours.
  AvatarData withIcon(IconCode? code) {
    if (kind == AvatarKind.photo) {
      return AvatarData(
        kind: kind,
        photoUrl: photoUrl,
        iconCode: code,
        initials: initials,
        colors: colors,
        border: border,
      );
    }
    final fromIcon = code == null ? const <String>[] : iconColors(code);
    return AvatarData(
      kind: code == null ? AvatarKind.initials : AvatarKind.icon,
      iconCode: code,
      initials: initials,
      colors: fromIcon.isNotEmpty ? fromIcon : colors,
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'photo_url': photoUrl,
    'icon_code': iconCode?.toJson(),
    'initials': initials,
    'colors': colors,
    'border': border?.toJson(),
  };

  /// An icon's colours in the BE's order: backgrounds, then icons, then
  /// borders, no repeats, no empty entries.
  static List<String> iconColors(IconCode code) {
    final out = <String>[];
    for (final c in [
      ...code.bgColors,
      ...code.iconColors,
      ...code.borderColors,
    ]) {
      if (c.isNotEmpty && !out.contains(c)) out.add(c);
    }
    return out;
  }

  /// The first letter of the first two words, upper-cased (the BE's rule).
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    String first(String w) => w.characters.firstOrNull ?? '';
    final letters = words.length == 1
        ? first(words.first)
        : '${first(words[0])}${first(words[1])}';
    return letters.toUpperCase();
  }

  /// The name-hash colour (the 12-colour palette) as `#RRGGBB`.
  static String nameColorHex(String name) {
    final argb = AppAvatar.colorFor(name).toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  List<Object?> get props => [
    kind,
    photoUrl,
    iconCode,
    initials,
    colors,
    border,
  ];
}

List<String> _strings(Object? v) =>
    v is List ? v.whereType<String>().toList() : const <String>[];
