import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';

/// Authenticated user — the subset of fields surfaced in the Phase 0 UI.
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.currency,
    this.email,
    this.iconCode,
  });

  final String id;
  final String username;
  final String displayName;
  final String currency;
  final String? email;
  final IconCode? iconCode;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      currency: (json['currency'] as String?) ?? 'THB',
      email: json['email'] as String?,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
    );
  }

  User copyWith({
    String? displayName,
    String? currency,
    String? email,
    IconCode? iconCode,
    bool clearEmail = false,
    bool clearIconCode = false,
  }) {
    return User(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      currency: currency ?? this.currency,
      email: clearEmail ? null : (email ?? this.email),
      iconCode: clearIconCode ? null : (iconCode ?? this.iconCode),
    );
  }

  @override
  List<Object?> get props =>
      [id, username, displayName, currency, email, iconCode];
}
