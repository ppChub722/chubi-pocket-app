import 'package:flutter/material.dart';

/// Curated icon set the user picks from when creating / editing a tag.
///
/// Tags are personal labels — anything the user wants to slice their
/// transactions by. The set below covers common patterns (gift,
/// reimbursable, travel, work, etc.) without being exhaustive. Users
/// can also stick with the default `label` for anything that doesn't
/// fit a preset.
///
/// Pending P1a schema bump: spec §3.8 currently has no `tags.icon`
/// column. Adding `icon VARCHAR NULLABLE` is part of the same set of
/// schema bumps queued in our doc-update list.
enum TagIconPreset {
  label('label', Icons.label_outline),
  flag('flag', Icons.flag_outlined),
  star('star', Icons.star_outline),
  favorite('favorite', Icons.favorite_outline),
  bolt('bolt', Icons.bolt),
  swapHoriz('swap_horiz', Icons.swap_horiz),
  cardGiftcard('card_giftcard', Icons.card_giftcard),
  subscriptions('subscriptions', Icons.subscriptions_outlined),
  flight('flight', Icons.flight),
  workOutline('work_outline', Icons.work_outline),
  schedule('schedule', Icons.schedule),
  localOffer('local_offer', Icons.local_offer_outlined),
  sell('sell', Icons.sell_outlined),
  emojiEvents('emoji_events', Icons.emoji_events_outlined),
  redeem('redeem', Icons.redeem),
  savings('savings', Icons.savings_outlined);

  const TagIconPreset(this.id, this.icon);

  final String id;
  final IconData icon;

  static TagIconPreset byId(String id) {
    return values.firstWhere(
      (p) => p.id == id,
      orElse: () => TagIconPreset.label,
    );
  }
}

/// Color palette for tags — duplicates the same 12 swatches used by
/// accounts and categories.
///
/// Pending P2 polish: extract the duplicated palette into a single
/// shared `BrandSwatch` so the three feature-local copies converge.
class TagColor {
  const TagColor._(this.id, this.color);

  final String id;
  final Color color;

  static const red = TagColor._('red', Color(0xFFE57373));
  static const pink = TagColor._('pink', Color(0xFFF06292));
  static const purple = TagColor._('purple', Color(0xFFBA68C8));
  static const deepPurple = TagColor._('deep_purple', Color(0xFF9575CD));
  static const indigo = TagColor._('indigo', Color(0xFF7986CB));
  static const blue = TagColor._('blue', Color(0xFF64B5F6));
  static const lightBlue = TagColor._('light_blue', Color(0xFF4FC3F7));
  static const cyan = TagColor._('cyan', Color(0xFF4DD0E1));
  static const green = TagColor._('green', Color(0xFFAED581));
  static const yellow = TagColor._('yellow', Color(0xFFFFD54F));
  static const orange = TagColor._('orange', Color(0xFFFFB74D));
  static const brown = TagColor._('brown', Color(0xFFA1887F));

  static const all = <TagColor>[
    red,
    pink,
    purple,
    deepPurple,
    indigo,
    blue,
    lightBlue,
    cyan,
    green,
    yellow,
    orange,
    brown,
  ];

  static TagColor byId(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => TagColor.blue,
    );
  }

  String toHex() {
    int channel(double c) => (c * 255).round() & 0xff;
    final r = channel(color.r).toRadixString(16).padLeft(2, '0');
    final g = channel(color.g).toRadixString(16).padLeft(2, '0');
    final b = channel(color.b).toRadixString(16).padLeft(2, '0');
    return '#${(r + g + b).toUpperCase()}';
  }

  static TagColor fromHex(String? hex) {
    if (hex == null) return TagColor.blue;
    final normalized = hex.toUpperCase();
    for (final c in all) {
      if (c.toHex() == normalized) return c;
    }
    return TagColor.blue;
  }
}
