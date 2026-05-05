import 'package:equatable/equatable.dart';

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
    this.icon,
    this.linkedUserId,
    this.lastUsedAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? email;
  final String? phone;
  final String? notes;
  final String? icon;
  final String? linkedUserId;
  final ContactStatus status;

  /// Bumped server-side whenever this contact is referenced by a new
  /// personal_debts row (split debtor). Drives the typeahead "recent first"
  /// sort on the split debtor picker. Null = never used.
  final DateTime? lastUsedAt;

  bool get isLinked => linkedUserId != null;
  bool get isArchived => status == ContactStatus.archived;

  /// Kept as an alias of [displayName] for one cycle so existing callers
  /// don't need to be touched all at once. New code should use
  /// [displayName] directly.
  String get effectiveName => displayName;

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      icon: json['icon'] as String?,
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
    String? icon,
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
      icon: icon ?? this.icon,
      linkedUserId: clearLinkedUserId ? null : (linkedUserId ?? this.linkedUserId),
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
        icon,
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
