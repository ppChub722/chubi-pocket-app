import 'package:equatable/equatable.dart';
import '../../../ui/ui.dart';

/// A membership role on a wallet (`account_members.role`).
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

/// A membership row's state: invited and not yet answered, in the wallet,
/// or gone (rows are append-only).
enum WalletMemberStatus { pending, active, left }

extension WalletMemberStatusWire on WalletMemberStatus {
  static WalletMemberStatus parse(String? s) => switch (s) {
    'pending' => WalletMemberStatus.pending,
    'left' => WalletMemberStatus.left,
    _ => WalletMemberStatus.active,
  };
}

/// One wallet member — `AccountMember` (the active embed on an Account:
/// no status / left_at) or `AccountMemberHistory` (the members tab: also
/// pending invites and past members). `name` is resolved by the BE and
/// `is_me` marks the caller's own row.
class WalletMember extends Equatable {
  const WalletMember({
    required this.id,
    required this.userId,
    String? name,
    // Source-compat alias of [name] (hub gallery sample data).
    String? displayName,
    required this.role,
    this.iconCode,
    this.status = WalletMemberStatus.active,
    this.joinedAt,
    this.leftAt,
    this.isMe = false,
  }) : name = name ?? displayName ?? '';

  final String id;
  final String userId;
  final String name;
  final WalletRole role;
  final IconCode? iconCode;
  final WalletMemberStatus status;

  /// ISO timestamp strings straight off the wire; rendered date-only.
  final String? joinedAt;
  final String? leftAt;

  /// The caller's own row.
  final bool isMe;

  /// Alias of [name].
  String get displayName => name;

  /// Invite sent, not yet accepted.
  bool get pending => status == WalletMemberStatus.pending;
  bool get isActive => status == WalletMemberStatus.active;
  bool get hasLeft => status == WalletMemberStatus.left;
  bool get isOwner => role == WalletRole.owner;

  factory WalletMember.fromJson(Map<String, dynamic> json) {
    return WalletMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      role: WalletRoleWire.parse(json['role'] as String?),
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      // The active embed has no status: it is active by definition.
      status: WalletMemberStatusWire.parse(json['status'] as String?),
      joinedAt: json['joined_at'] as String?,
      leftAt: json['left_at'] as String?,
      isMe: (json['is_me'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    role,
    iconCode,
    status,
    joinedAt,
    leftAt,
    isMe,
  ];
}
