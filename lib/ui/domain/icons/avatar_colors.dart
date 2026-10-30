import 'package:equatable/equatable.dart';

import '../people/avatar_data.dart';

/// A photo's ring styles (the icon maker's border ids; none = no ring).
abstract final class AvatarBorderStyle {
  static const none = 'none';
  static const thin = 'thin';
  static const thick = 'thick';
  static const dashed = 'dashed';

  /// In the order the colour-only icon maker offers them.
  static const all = [none, thin, thick, dashed];
}

/// What the icon maker's colour-only mode edits for a photo source (0.4.2
/// 1b, `avatar_settings` colours + border): profile colours 1–3 ('' =
/// unset), the ring style and its colour. Colours past 3 ([extra]) are kept
/// as they are. Values are colour specs (a theme token or `#rrggbb`).
class AvatarColorsDraft extends Equatable {
  const AvatarColorsDraft({
    this.slots = const ['', '', ''],
    this.extra = const [],
    this.borderStyle = AvatarBorderStyle.none,
    this.borderColor = '',
  }) : assert(slots.length == slotCount, 'three colour slots');

  /// From the saved `avatar_settings.colors` / `border`.
  factory AvatarColorsDraft.from(List<String> colors, AvatarBorder? border) {
    String at(int i) => i < colors.length ? colors[i] : '';
    final style = border == null || border.isNone
        ? AvatarBorderStyle.none
        : border.style;
    return AvatarColorsDraft(
      slots: [at(0), at(1), at(2)],
      extra: colors.length > slotCount
          ? colors.sublist(slotCount)
          : const <String>[],
      borderStyle: AvatarBorderStyle.all.contains(style)
          ? style
          : AvatarBorderStyle.thin,
      borderColor: border == null || border.colors.isEmpty
          ? ''
          : border.colors.first,
    );
  }

  static const slotCount = 3;

  /// The ring colour picked when a ring is turned on with none set.
  static const defaultBorderColor = '@presetThemeColor1';

  /// Colours 1–3, '' = unset.
  final List<String> slots;

  /// Colours 4… (not edited here, saved back as they were).
  final List<String> extra;
  final String borderStyle;

  /// '' = none picked yet.
  final String borderColor;

  bool get hasBorder => borderStyle != AvatarBorderStyle.none;

  /// Slot [i] set to [spec] ('' clears it).
  AvatarColorsDraft withSlot(int i, String spec) {
    if (i < 0 || i >= slotCount) return this;
    final next = [...slots]..[i] = spec;
    return _copy(slots: next);
  }

  /// Turning a ring on with no colour picks the first set colour (else a
  /// theme colour), so the ring always shows.
  AvatarColorsDraft withBorderStyle(String style) {
    if (!AvatarBorderStyle.all.contains(style)) return this;
    final color = style != AvatarBorderStyle.none && borderColor.isEmpty
        ? slots.firstWhere(
            (s) => s.isNotEmpty,
            orElse: () => defaultBorderColor,
          )
        : borderColor;
    return _copy(borderStyle: style, borderColor: color);
  }

  AvatarColorsDraft withBorderColor(String spec) => _copy(borderColor: spec);

  /// `avatar_settings.colors`: the set slots in order (an unset slot is
  /// just missing, as the BE keeps them), then [extra].
  List<String> get colors => [
    for (final s in slots)
      if (s.isNotEmpty) s,
    ...extra.where((s) => s.isNotEmpty),
  ];

  /// `avatar_settings.border`: null when there is no ring.
  AvatarBorder? get border => hasBorder
      ? AvatarBorder(
          style: borderStyle,
          colors: borderColor.isEmpty ? const [] : [borderColor],
        )
      : null;

  /// The avatar's profile colours as the BE builds them for a photo: the
  /// picked colours, then the ring's, no repeats (may be empty: the BE then
  /// falls back to the icon's, then the name colour).
  List<String> get profileColors {
    final out = <String>[];
    for (final c in [...colors, ...?border?.colors]) {
      if (c.isNotEmpty && !out.contains(c)) out.add(c);
    }
    return out;
  }

  AvatarColorsDraft _copy({
    List<String>? slots,
    String? borderStyle,
    String? borderColor,
  }) => AvatarColorsDraft(
    slots: slots ?? this.slots,
    extra: extra,
    borderStyle: borderStyle ?? this.borderStyle,
    borderColor: borderColor ?? this.borderColor,
  );

  @override
  List<Object?> get props => [slots, extra, borderStyle, borderColor];
}
