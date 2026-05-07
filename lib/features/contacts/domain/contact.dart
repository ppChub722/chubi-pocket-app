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
    this.linkedUserIconCode,
    this.linkedUserDisplayName,
    this.linkedUserEmail,
    this.lastUsedAt,
  });

  final String id;
  final String userId;

  /// B's local copy of the contact's name. Always present. For linked
  /// contacts, prefer [effectiveDisplayName] for display — that
  /// projects the linked user's live name; the contact's own
  /// [displayName] is a snapshot fallback for after unlink.
  final String displayName;

  /// Same fallback story as [displayName]: stored on the contact row,
  /// used directly when unlinked, but [effectiveEmail] should be used
  /// for display so linked contacts mirror the user's current email.
  final String? email;
  final String? phone;
  final String? notes;
  final IconCode? iconCode;
  final String? linkedUserId;

  /// Snapshot of the linked user's profile icon at read time (server-projected
  /// from `users.icon_code` when `linked_user_id` is set). Null when the
  /// contact isn't linked or the linked user hasn't set one.
  final IconCode? linkedUserIconCode;

  /// Live-projected from `users.display_name` when linked. Null when not
  /// linked. Driven by post-1c policy: linked-contact display fields
  /// source from the user record so they stay current automatically.
  final String? linkedUserDisplayName;

  /// Live-projected from `users.email` when linked. Same rule as
  /// [linkedUserDisplayName].
  final String? linkedUserEmail;

  final ContactStatus status;
  final DateTime? lastUsedAt;

  bool get isLinked => linkedUserId != null;
  bool get isArchived => status == ContactStatus.archived;

  /// Backwards-compatible alias kept for older call sites that just want
  /// "the name to render". Prefer [effectiveDisplayName] going forward —
  /// it makes the "linked wins, fall back to local snapshot" rule
  /// explicit at the call site.
  String get effectiveName => effectiveDisplayName;

  /// Display rule: when linked, use the linked user's current
  /// `display_name`; otherwise use the contact's own stored copy.
  String get effectiveDisplayName =>
      linkedUserDisplayName ?? displayName;

  /// Same rule as [effectiveDisplayName] for email.
  String? get effectiveEmail => linkedUserEmail ?? email;

  /// Display precedence per spec §4.4: linked user's icon wins over the
  /// contact's own icon. (avatar_url was dropped in migration 33.)
  IconCode? get effectiveIconCode => linkedUserIconCode ?? iconCode;

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
      linkedUserIconCode: json['linked_user_icon_code'] != null
          ? IconCode.fromJson(
              json['linked_user_icon_code'] as Map<String, dynamic>)
          : null,
      linkedUserDisplayName: json['linked_user_display_name'] as String?,
      linkedUserEmail: json['linked_user_email'] as String?,
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
    IconCode? linkedUserIconCode,
    String? linkedUserDisplayName,
    String? linkedUserEmail,
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
      linkedUserIconCode: clearLinkedUserId
          ? null
          : (linkedUserIconCode ?? this.linkedUserIconCode),
      linkedUserDisplayName: clearLinkedUserId
          ? null
          : (linkedUserDisplayName ?? this.linkedUserDisplayName),
      linkedUserEmail: clearLinkedUserId
          ? null
          : (linkedUserEmail ?? this.linkedUserEmail),
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
        linkedUserIconCode,
        linkedUserDisplayName,
        linkedUserEmail,
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

/// Public-profile slice the BE returns for the inbox tap-flow prefill.
/// Backed by `GET /v1/contacts/link-requests/:id/sender-profile` —
/// gated to the request's recipient while the request is still pending.
class SenderProfile extends Equatable {
  const SenderProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.iconCode,
  });

  final String id;
  final String displayName;
  final String? email;
  final IconCode? iconCode;

  factory SenderProfile.fromJson(Map<String, dynamic> json) {
    return SenderProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, displayName, email, iconCode];
}

