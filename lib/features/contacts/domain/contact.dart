import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';

enum ContactStatus { active, archived }

class Contact extends Equatable {
  const Contact({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.status,
    this.email,
    this.phone,
    this.notes,
    this.iconCode,
    this.linkedUserId,
    this.lastUsedAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? email;
  final String? phone;
  final String? notes;
  final IconCode? iconCode;
  final String? linkedUserId;
  final ContactStatus status;
  final DateTime? lastUsedAt;

  bool get isLinked => linkedUserId != null;
  bool get isArchived => status == ContactStatus.archived;
  String get effectiveName => displayName;

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      linkedUserId: json['linked_user_id'] as String?,
      status: (json['status'] as String?) == 'archived'
          ? ContactStatus.archived
          : ContactStatus.active,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
    );
  }

  Contact copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? notes,
    IconCode? iconCode,
    String? linkedUserId,
    ContactStatus? status,
    DateTime? lastUsedAt,
    bool clearLinkedUserId = false,
  }) {
    return Contact(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      iconCode: iconCode ?? this.iconCode,
      linkedUserId:
          clearLinkedUserId ? null : (linkedUserId ?? this.linkedUserId),
      status: status ?? this.status,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        displayName,
        email,
        phone,
        notes,
        iconCode,
        linkedUserId,
        status,
        lastUsedAt,
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
