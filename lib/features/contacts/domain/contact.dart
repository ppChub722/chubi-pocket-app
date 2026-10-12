import 'package:equatable/equatable.dart';
import '../../../ui/ui.dart';

enum ContactStatus { active, archived }

/// `LinkedUser` — the app account a contact is linked to (live profile).
class LinkedUser extends Equatable {
  const LinkedUser({
    required this.id,
    required this.displayName,
    this.email,
    this.iconCode,
  });

  final String id;
  final String displayName;
  final String? email;
  final IconCode? iconCode;

  factory LinkedUser.fromJson(Map<String, dynamic> json) => LinkedUser(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    email: json['email'] as String?,
    iconCode: json['icon_code'] != null
        ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
        : null,
  );

  @override
  List<Object?> get props => [id, displayName, email, iconCode];
}

/// `Contact` (API v2). [name], [email] and [iconCode] are RESOLVED by the BE
/// (nickname → linked profile → own); the client never re-resolves them.
class Contact extends Equatable {
  const Contact({
    required this.id,
    required this.name,
    required this.displayName,
    required this.status,
    this.nickname,
    this.showNickname = true,
    this.email,
    this.phone,
    this.description,
    this.note,
    this.iconCode,
    this.linkedUser,
    this.lastUsedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// Resolved name: the nickname when set and [showNickname], else the linked
  /// user's live profile name, else [displayName].
  final String name;

  /// My own label for them. Null when unset.
  final String? nickname;

  /// Use [nickname] as [name]; only matters when a nickname is set.
  final bool showNickname;

  /// The contact's own stored name (what the edit field edits).
  final String displayName;

  /// Resolved: the linked user's email when linked, else the contact's own.
  final String? email;
  final String? phone;
  final String? description;
  final String? note;

  /// Resolved: the linked user's icon when linked, else the contact's own.
  final IconCode? iconCode;
  final LinkedUser? linkedUser;
  final ContactStatus status;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLinked => linkedUser != null;
  bool get isArchived => status == ContactStatus.archived;

  // ── Deprecated source-compat getters (other features still read these) ──
  @Deprecated('Use name')
  String get effectiveName => name;
  @Deprecated('Use name')
  String get effectiveDisplayName => name;
  @Deprecated('Use email')
  String? get effectiveEmail => email;
  @Deprecated('Use iconCode')
  IconCode? get effectiveIconCode => iconCode;
  @Deprecated('Use linkedUser?.id')
  String? get linkedUserId => linkedUser?.id;
  @Deprecated('Use linkedUser?.displayName')
  String? get linkedUserDisplayName => linkedUser?.displayName;
  @Deprecated('Use linkedUser?.email')
  String? get linkedUserEmail => linkedUser?.email;
  @Deprecated('Use linkedUser?.iconCode')
  IconCode? get linkedUserIconCode => linkedUser?.iconCode;

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      showNickname: json['show_nickname'] as bool? ?? true,
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      note: json['note'] as String?,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      linkedUser: json['linked_user'] != null
          ? LinkedUser.fromJson(json['linked_user'] as Map<String, dynamic>)
          : null,
      status: (json['status'] as String?) == 'archived'
          ? ContactStatus.archived
          : ContactStatus.active,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    nickname,
    showNickname,
    displayName,
    email,
    phone,
    description,
    note,
    iconCode,
    linkedUser,
    status,
    lastUsedAt,
    createdAt,
    updatedAt,
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

/// `ContactDetail` — a [Contact] plus the unlinked split names
/// (`?include=unlinked_names`).
class ContactDetail extends Equatable {
  const ContactDetail({required this.contact, this.unlinkedNames = const []});

  final Contact contact;
  final List<UnlinkedName> unlinkedNames;

  factory ContactDetail.fromJson(Map<String, dynamic> json) => ContactDetail(
    contact: Contact.fromJson(json),
    unlinkedNames: ((json['unlinked_names'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(UnlinkedName.fromJson)
        .toList(),
  );

  @override
  List<Object?> get props => [contact, unlinkedNames];
}

/// `{contact, absorbed_count}` — absorb and create.
class AbsorbResult extends Equatable {
  const AbsorbResult({required this.contact, required this.absorbedCount});
  final Contact contact;
  final int absorbedCount;

  factory AbsorbResult.fromJson(Map<String, dynamic> json) => AbsorbResult(
    contact: Contact.fromJson(json['contact'] as Map<String, dynamic>),
    absorbedCount: (json['absorbed_count'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [contact, absorbedCount];
}

/// `{id, splits_restored}`.
class DeleteContactResult extends Equatable {
  const DeleteContactResult({required this.id, required this.splitsRestored});
  final String id;
  final int splitsRestored;

  factory DeleteContactResult.fromJson(Map<String, dynamic> json) =>
      DeleteContactResult(
        id: json['id'] as String,
        splitsRestored: (json['splits_restored'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, splitsRestored];
}

/// Public-profile slice the BE returns for the inbox tap-flow prefill.
/// Backed by `GET /v1/contacts/link-requests/:id/sender-profile`.
/// [contactId] = the caller's contact that already links to this sender.
class SenderProfile extends Equatable {
  const SenderProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.iconCode,
    this.contactId,
  });

  final String id;
  final String displayName;
  final String? email;
  final IconCode? iconCode;
  final String? contactId;

  factory SenderProfile.fromJson(Map<String, dynamic> json) {
    return SenderProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      contactId: json['contact_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, displayName, email, iconCode, contactId];
}
