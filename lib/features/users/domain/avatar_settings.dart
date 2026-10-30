import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';

/// Where my profile picture comes from (`avatar_settings.source`).
abstract final class AvatarSource {
  static const icon = 'icon';
  static const upload = 'upload';
  static const telegram = 'telegram';
  static const line = 'line';
  static const google = 'google';
}

/// The profile picture I picked (0.4.2 1b, `users.avatar_settings`; only I
/// see it, on GET /users/me — everyone else gets the resolved `avatar`).
class AvatarSettings extends Equatable {
  const AvatarSettings({
    this.source = AvatarSource.icon,
    this.colors = const [],
    this.border,
  });

  factory AvatarSettings.fromJson(Map<String, dynamic> json) => AvatarSettings(
    source: (json['source'] as String?) ?? AvatarSource.icon,
    colors: json['colors'] is List
        ? (json['colors'] as List).whereType<String>().toList()
        : const [],
    border: json['border'] is Map
        ? AvatarBorder.fromJson((json['border'] as Map).cast<String, dynamic>())
        : null,
  );

  /// icon (the icon maker's icon) / upload / telegram / line / google.
  final String source;

  /// A photo source's profile colours, in order (≤ 8; the colour-only icon
  /// maker edits 1–3). Ignored while [source] is icon.
  final List<String> colors;

  /// A photo source's ring; null = none.
  final AvatarBorder? border;

  bool get isIcon => source == AvatarSource.icon;

  AvatarSettings copyWith({
    String? source,
    List<String>? colors,
    AvatarBorder? border,
    bool clearBorder = false,
  }) => AvatarSettings(
    source: source ?? this.source,
    colors: colors ?? this.colors,
    border: clearBorder ? null : (border ?? this.border),
  );

  Map<String, dynamic> toJson() => {
    'source': source,
    'colors': colors,
    'border': border?.toJson(),
  };

  @override
  List<Object?> get props => [source, colors, border];
}
