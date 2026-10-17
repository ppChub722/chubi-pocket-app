import 'package:equatable/equatable.dart';
import '../../../ui/ui.dart';

/// The default wallet as `/users/me` returns it (`default_account`).
class DefaultWalletRef extends Equatable {
  const DefaultWalletRef({required this.id, required this.name, this.iconCode});

  factory DefaultWalletRef.fromJson(Map<String, dynamic> json) =>
      DefaultWalletRef(
        id: json['id'] as String,
        name: json['name'] as String,
        iconCode: json['icon_code'] is Map
            ? IconCode.fromJson(
                (json['icon_code'] as Map).cast<String, dynamic>(),
              )
            : null,
      );

  final String id;
  final String name;
  final IconCode? iconCode;

  @override
  List<Object?> get props => [id, name, iconCode];
}

/// `/users/me` `notification_summary`: the settings tile's numbers (mutable
/// types not muted, types running automatically).
class NotificationSummary extends Equatable {
  const NotificationSummary({required this.on, required this.auto});

  factory NotificationSummary.fromJson(Map<String, dynamic> json) =>
      NotificationSummary(
        on: (json['on'] as num?)?.toInt() ?? 0,
        auto: (json['auto'] as num?)?.toInt() ?? 0,
      );

  final int on;
  final int auto;

  @override
  List<Object?> get props => [on, auto];
}

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
    this.moneyStyle,
    this.moneyDecimals,
    this.defaultAccount,
    this.autoCopyOwnEventBills = false,
    this.notificationSummary,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String username;
  final String displayName;

  /// The user's one currency: a label, never converted; editable on the
  /// settings home.
  final String currency;
  final String? email;
  final IconCode? iconCode;

  /// Server preference `fee_category_id` (spec 15 §7): the expense category
  /// fee drafts from bank slips get. Only on `GET`/`PUT /users/me` —
  /// login answers without preferences, so it may be stale until then.
  final String? feeCategoryId;

  /// Server preference `money_style` (owner 2026-10-17): how amounts mark
  /// income / expense; null = a user from before it (+/− in colour). Only on
  /// `GET`/`PUT /users/me`, like [feeCategoryId].
  final String? moneyStyle;

  /// Server preference `money_decimals`: always / never / auto (null = auto).
  final String? moneyDecimals;

  /// The default wallet (`default_account`; null = none).
  final DefaultWalletRef? defaultAccount;

  /// `auto_copy_own_event_bills`: a bill I record in an event also lands in my
  /// own book (set on the event settings, not here).
  final bool autoCopyOwnEventBills;

  /// The settings tile's numbers; null when the answer has none (login).
  final NotificationSummary? notificationSummary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      feeCategoryId: switch (json['preferences']) {
        {'fee_category_id': final String id} => id,
        _ => null,
      },
      moneyStyle: switch (json['preferences']) {
        {'money_style': final String style} => style,
        _ => null,
      },
      moneyDecimals: switch (json['preferences']) {
        {'money_decimals': final String decimals} => decimals,
        _ => null,
      },
      defaultAccount: json['default_account'] is Map
          ? DefaultWalletRef.fromJson(
              (json['default_account'] as Map).cast<String, dynamic>(),
            )
          : null,
      autoCopyOwnEventBills:
          (json['auto_copy_own_event_bills'] as bool?) ?? false,
      notificationSummary: json['notification_summary'] is Map
          ? NotificationSummary.fromJson(
              (json['notification_summary'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  User copyWith({
    String? displayName,
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
      currency: currency,
      email: clearEmail ? null : (email ?? this.email),
      iconCode: clearIconCode ? null : (iconCode ?? this.iconCode),
      createdAt: createdAt,
      updatedAt: updatedAt,
      defaultAccount: defaultAccount,
      autoCopyOwnEventBills: autoCopyOwnEventBills,
      notificationSummary: notificationSummary,
      feeCategoryId: clearFeeCategory
          ? null
          : (feeCategoryId ?? this.feeCategoryId),
      moneyStyle: moneyStyle,
      moneyDecimals: moneyDecimals,
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
    moneyStyle,
    moneyDecimals,
    defaultAccount,
    autoCopyOwnEventBills,
    notificationSummary,
    createdAt,
    updatedAt,
  ];
}
