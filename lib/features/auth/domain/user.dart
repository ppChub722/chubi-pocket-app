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
    this.feeCategoryId,
  });

  final String id;
  final String username;
  final String displayName;
  final String currency;
  final String? email;
  final IconCode? iconCode;

  /// Server preference `fee_category_id` (spec 15 §7): the expense category
  /// fee drafts from bank slips get. Only on `GET`/`PUT /users/me` —
  /// login answers without preferences, so it may be stale until then.
  final String? feeCategoryId;

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
      feeCategoryId: switch (json['preferences']) {
        {'fee_category_id': final String id} => id,
        _ => null,
      },
    );
  }

  User copyWith({
    String? displayName,
    String? currency,
    String? email,
    IconCode? iconCode,
    bool clearEmail = false,
    bool clearIconCode = false,
    String? feeCategoryId,
    bool clearFeeCategory = false,
  }) {
    return User(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      currency: currency ?? this.currency,
      email: clearEmail ? null : (email ?? this.email),
      iconCode: clearIconCode ? null : (iconCode ?? this.iconCode),
      feeCategoryId: clearFeeCategory
          ? null
          : (feeCategoryId ?? this.feeCategoryId),
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    currency,
    email,
    iconCode,
    feeCategoryId,
  ];
}
