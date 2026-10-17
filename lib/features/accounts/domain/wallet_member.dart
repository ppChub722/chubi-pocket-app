import 'package:equatable/equatable.dart';
import '../../../ui/ui.dart';

enum WalletRole { owner, member }

extension WalletRoleWire on WalletRole {
  String get wire => this == WalletRole.owner ? 'owner' : 'member';

  static WalletRole parse(String? s) =>
      s == 'owner' ? WalletRole.owner : WalletRole.member;
}

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

enum WalletMemberStatus { pending, active, left }

extension WalletMemberStatusWire on WalletMemberStatus {
  static WalletMemberStatus parse(String? s) => switch (s) {
    'pending' => WalletMemberStatus.pending,
    'left' => WalletMemberStatus.left,
    _ => WalletMemberStatus.active,
  };
}

class WalletMember extends Equatable {
  const WalletMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.role,
    this.iconCode,
    this.status = WalletMemberStatus.active,
    this.joinedAt,
    this.leftAt,
    this.isMe = false,
  });

  final String id;
  final String userId;
  final String name;
  final WalletRole role;
  final IconCode? iconCode;
  final WalletMemberStatus status;

  final String? joinedAt;
  final String? leftAt;

  final bool isMe;

  String get displayName => name;

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
