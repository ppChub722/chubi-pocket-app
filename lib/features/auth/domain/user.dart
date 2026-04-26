import 'package:equatable/equatable.dart';

/// Authenticated user — the subset of fields surfaced in the Phase 0 UI.
///
/// `/users/me` returns more (`status`, `preferences`, `email_verified_at`,
/// `created_at`) — those will be added when Phase 1+ settings need them.
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.currency,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String currency;
  final String? email;
  final String? avatarUrl;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      currency: (json['currency'] as String?) ?? 'THB',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  User copyWith({
    String? displayName,
    String? currency,
    String? email,
    String? avatarUrl,
    bool clearEmail = false,
    bool clearAvatar = false,
  }) {
    return User(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      currency: currency ?? this.currency,
      email: clearEmail ? null : (email ?? this.email),
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  @override
  List<Object?> get props =>
      [id, username, displayName, currency, email, avatarUrl];
}
