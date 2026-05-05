import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Unified icon descriptor stored as JSONB on the server.
///
/// Shape mirrors the BE `icon_code` column:
///   {icon, iconColors, background, bgColors, border, borderColors}
///
/// Two display styles exist in the app:
/// - background (accounts, categories, projects): solid bg + white icon
/// - iconColor (tags): transparent bg + tinted icon
class IconCode extends Equatable {
  const IconCode({
    this.icon,
    this.iconColors = const [],
    this.background,
    this.bgColors = const [],
    this.border,
    this.borderColors = const [],
  });

  final String? icon;
  final List<String> iconColors;
  final String? background;
  final List<String> bgColors;
  final String? border;
  final List<String> borderColors;

  Color? get resolvedBgColor =>
      bgColors.isNotEmpty ? _hexToColor(bgColors.first) : null;

  Color? get resolvedIconColor =>
      iconColors.isNotEmpty ? _hexToColor(iconColors.first) : null;

  /// The accent used for card borders, balance text, and chip tints.
  /// Falls back to brand blue when neither colour slot is set.
  Color get accentColor =>
      resolvedBgColor ?? resolvedIconColor ?? const Color(0xFF64B5F6);

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return const Color(0xFF64B5F6);
    return Color(0xFF000000 | value);
  }

  factory IconCode.fromJson(Map<String, dynamic> json) {
    List<String> strs(dynamic v) {
      if (v is List) return v.whereType<String>().toList();
      return const [];
    }

    return IconCode(
      icon: json['icon'] as String?,
      iconColors: strs(json['iconColors']),
      background: json['background'] as String?,
      bgColors: strs(json['bgColors']),
      border: json['border'] as String?,
      borderColors: strs(json['borderColors']),
    );
  }

  Map<String, dynamic> toJson() => {
        'icon': icon,
        'iconColors': iconColors,
        'background': background,
        'bgColors': bgColors,
        'border': border,
        'borderColors': borderColors,
      };

  IconCode copyWith({
    String? icon,
    List<String>? iconColors,
    String? background,
    List<String>? bgColors,
    String? border,
    List<String>? borderColors,
  }) {
    return IconCode(
      icon: icon ?? this.icon,
      iconColors: iconColors ?? this.iconColors,
      background: background ?? this.background,
      bgColors: bgColors ?? this.bgColors,
      border: border ?? this.border,
      borderColors: borderColors ?? this.borderColors,
    );
  }

  @override
  List<Object?> get props =>
      [icon, iconColors, background, bgColors, border, borderColors];
}
