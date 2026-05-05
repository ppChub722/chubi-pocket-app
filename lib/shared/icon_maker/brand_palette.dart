import 'package:flutter/material.dart';

/// One colour swatch in the shared brand palette.
class BrandSwatch {
  const BrandSwatch._(this.id, this.color);

  final String id;
  final Color color;

  String get hex {
    final v = color.toARGB32() & 0x00FFFFFF;
    return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

/// 12-colour palette shared across accounts, categories, tags, and projects.
///
/// Replaces the three identical `AccountColor`, `CategoryColor`, `TagColor`
/// classes. One palette to maintain — one place to add a swatch.
class BrandPalette {
  BrandPalette._();

  static const red = BrandSwatch._('red', Color(0xFFE57373));
  static const pink = BrandSwatch._('pink', Color(0xFFF06292));
  static const purple = BrandSwatch._('purple', Color(0xFFBA68C8));
  static const deepPurple = BrandSwatch._('deep_purple', Color(0xFF9575CD));
  static const indigo = BrandSwatch._('indigo', Color(0xFF7986CB));
  static const blue = BrandSwatch._('blue', Color(0xFF64B5F6));
  static const lightBlue = BrandSwatch._('light_blue', Color(0xFF4FC3F7));
  static const cyan = BrandSwatch._('cyan', Color(0xFF4DD0E1));
  static const green = BrandSwatch._('green', Color(0xFFAED581));
  static const yellow = BrandSwatch._('yellow', Color(0xFFFFD54F));
  static const orange = BrandSwatch._('orange', Color(0xFFFFB74D));
  static const brown = BrandSwatch._('brown', Color(0xFFA1887F));

  static const all = <BrandSwatch>[
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

  static BrandSwatch byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => blue);

  static BrandSwatch byHex(String? hex) {
    if (hex == null) return blue;
    final normalized = hex.toUpperCase();
    return all.firstWhere((s) => s.hex == normalized, orElse: () => blue);
  }
}
