import 'package:equatable/equatable.dart';

enum ContactStatus { active, archived }

class Contact extends Equatable {
  const Contact({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.status,
    this.nickname,
    this.email,
    this.phone,
    this.notes,
    this.icon,
    this.linkedUserId,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? nickname;
  final String? email;
  final String? phone;
  final String? notes;
  final String? icon;
  final String? linkedUserId;
  final ContactStatus status;

  bool get isLinked => linkedUserId != null;
  bool get isArchived => status == ContactStatus.archived;
  String get effectiveName => nickname?.isNotEmpty == true ? nickname! : displayName;

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      nickname: json['nickname'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      icon: json['icon'] as String?,
      linkedUserId: json['linked_user_id'] as String?,
      status: (json['status'] as String?) == 'archived'
          ? ContactStatus.archived
          : ContactStatus.active,
    );
  }

  Contact copyWith({
    String? displayName,
    String? nickname,
    String? email,
    String? phone,
    String? notes,
    String? icon,
    String? linkedUserId,
    ContactStatus? status,
    bool clearLinkedUserId = false,
  }) {
    return Contact(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      icon: icon ?? this.icon,
      linkedUserId: clearLinkedUserId ? null : (linkedUserId ?? this.linkedUserId),
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        displayName,
        nickname,
        email,
        phone,
        notes,
        icon,
        linkedUserId,
        status,
      ];
}

class UnlinkedName extends Equatable {
  const UnlinkedName({required this.name, required this.count});
  final String name;
  final int count;

  factory UnlinkedName.fromJson(Map<String, dynamic> json) {
    return UnlinkedName(
      name: json['name'] as String,
      count: (json['count'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [name, count];
}
