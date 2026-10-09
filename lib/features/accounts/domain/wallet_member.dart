import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';

/// A membership role on a wallet (spec §14/3.1 `account_members.role`).
enum WalletRole { owner, member }

extension WalletRoleWire on WalletRole {
  String get wire => this == WalletRole.owner ? 'owner' : 'member';

  static WalletRole parse(String? s) =>
      s == 'owner' ? WalletRole.owner : WalletRole.member;
}

/// Per-member report visibility (spec §14/5). `none` is the default once
/// a wallet becomes shared; each member can flip their own back.
enum WalletReportScope { none, own, all }

extension WalletReportScopeWire on WalletReportScope {
  String get wire {
    switch (this) {
      case WalletReportScope.none:
        return 'none';
      case WalletReportScope.own:
        return 'own';
      case WalletReportScope.all:
        return 'all';
    }
  }

  static WalletReportScope parse(String? s) {
    switch (s) {
      case 'own':
        return WalletReportScope.own;
      case 'all':
        return WalletReportScope.all;
      default:
        return WalletReportScope.none;
    }
  }
}

/// One `account_members` row (spec §14/3.1, API §14 pinned contract).
///
/// The pinned `GET /v1/accounts` embed carries active members only
/// (`id / user_id / display_name / icon_code / role / joined_at`).
/// The member-management screen additionally reads the full membership
/// history (`left_at` set on leave — rows are append-only) and the
/// pending state of a not-yet-accepted invite (project-invite pattern).
class WalletMember extends Equatable {
  const WalletMember({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.role,
    this.iconCode,
    this.joinedAt,
    this.leftAt,
    this.pending = false,
  });

  final String id;
  final String userId;
  final String displayName;
  final WalletRole role;
  final IconCode? iconCode;

  /// ISO timestamp strings straight off the wire; rendered date-only.
  final String? joinedAt;
  final String? leftAt;

  /// Invite sent, not yet accepted (notification-pattern invite).
  final bool pending;

  bool get isActive => leftAt == null && !pending;
  bool get hasLeft => leftAt != null;
  bool get isOwner => role == WalletRole.owner;

  factory WalletMember.fromJson(Map<String, dynamic> json) {
    return WalletMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? '',
      role: WalletRoleWire.parse(json['role'] as String?),
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      joinedAt: json['joined_at'] as String?,
      leftAt: json['left_at'] as String?,
      pending: json['status'] == 'pending',
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    displayName,
    role,
    iconCode,
    joinedAt,
    leftAt,
    pending,
  ];
}
