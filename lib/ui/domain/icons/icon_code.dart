import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../atoms/app_avatar.dart';
import '../../tokens/app/app_colors.dart';
import 'color_token.dart';

class IconCode extends Equatable {
  const IconCode({
    this.icon,
    this.iconColors = const [],
    this.background,
    this.bgColors = const [],
    this.border,
    this.borderColors = const [],
    this.shape,
  });

  final String? icon;
  final List<String> iconColors;
  final String? background;
  final List<String> bgColors;
  final String? border;
  final List<String> borderColors;
  final String? shape;

  Color? get resolvedBgColor =>
      bgColors.isNotEmpty ? hexToColor(bgColors.first) : null;

  Color? get resolvedIconColor =>
      iconColors.isNotEmpty ? hexToColor(iconColors.first) : null;

  Color get accentColor =>
      resolvedBgColor ?? resolvedIconColor ?? const Color(0xFF64B5F6);

  Color accentColorFor(AppColors palette) {
    if (bgColors.isNotEmpty) return resolveColor(bgColors.first, palette);
    if (iconColors.isNotEmpty) return resolveColor(iconColors.first, palette);
    return palette.primary;
  }

  Color? bgColorFor(AppColors palette) =>
      bgColors.isNotEmpty ? resolveColor(bgColors.first, palette) : null;

  static Color hexToColor(String hex) {
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
      shape: json['shape'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'icon': icon,
    'iconColors': iconColors,
    'background': background,
    'bgColors': bgColors,
    'border': border,
    'borderColors': borderColors,
    if (shape != null) 'shape': shape,
  };

  IconCode copyWith({
    String? icon,
    List<String>? iconColors,
    String? background,
    List<String>? bgColors,
    String? border,
    List<String>? borderColors,
    String? shape,
  }) {
    return IconCode(
      icon: icon ?? this.icon,
      iconColors: iconColors ?? this.iconColors,
      background: background ?? this.background,
      bgColors: bgColors ?? this.bgColors,
      border: border ?? this.border,
      borderColors: borderColors ?? this.borderColors,
      shape: shape ?? this.shape,
    );
  }

  @override
  List<Object?> get props => [
    icon,
    iconColors,
    background,
    bgColors,
    border,
    borderColors,
    shape,
  ];
}

extension IconCodeTint on IconCode? {
  Color tintFor(AppColors palette, {Color? fallback, String? avatarName}) {
    final code = this;
    if (code != null) {
      if (code.bgColors.isNotEmpty) {
        return resolveColor(code.bgColors.first, palette);
      }
      if (code.iconColors.isNotEmpty) {
        return resolveColor(code.iconColors.first, palette);
      }
    }
    final name = avatarName?.trim() ?? '';
    if (name.isNotEmpty) return AppAvatar.colorFor(name);
    return fallback ?? palette.primary;
  }
}
