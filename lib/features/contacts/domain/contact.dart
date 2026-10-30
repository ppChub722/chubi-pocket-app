import 'package:equatable/equatable.dart';
import '../../../ui/ui.dart';

enum ContactStatus { active, archived }

class LinkedUser extends Equatable {
  const LinkedUser({
    required this.id,
    required this.displayName,
    this.username,
    this.email,
    this.iconCode,
    AvatarData? avatar,
  }) : _avatar = avatar;

  final String id;
  final String displayName;

  final String? username;
  final String? email;
  final IconCode? iconCode;
  final AvatarData? _avatar;

  /// 0.4.2 1b: the BE's avatar; built from the name + icon when absent.
  AvatarData get avatar =>
      _avatar ?? AvatarData.forName(displayName, iconCode: iconCode);

  factory LinkedUser.fromJson(Map<String, dynamic> json) {
    final name = json['display_name'] as String;
    final avatar = AvatarData.parse(json, name: name);
    return LinkedUser(
      id: json['id'] as String,
      displayName: name,
      username: json['username'] as String?,
      email: json['email'] as String?,
      iconCode: avatar.iconCode,
      avatar: avatar,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    username,
    email,
    iconCode,
    _avatar,
  ];
}

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
    AvatarData? avatar,
  }) : _avatar = avatar;

  final String id;

  final String name;

  final String? nickname;

  final bool showNickname;

  final String displayName;

  final String? email;
  final String? phone;
  final String? description;
  final String? note;

  /// The contact's icon as the BE resolves it (`avatar.icon_code`: the
  /// linked user's when linked, else the contact's own; create / update
  /// still send `icon_code`).
  final IconCode? iconCode;
  final AvatarData? _avatar;

  /// 0.4.2 1b: the BE's avatar; built from the name + icon when absent.
  AvatarData get avatar =>
      _avatar ?? AvatarData.forName(name, iconCode: iconCode);
  final LinkedUser? linkedUser;
  final ContactStatus status;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLinked => linkedUser != null;
  bool get isArchived => status == ContactStatus.archived;

  factory Contact.fromJson(Map<String, dynamic> json) {
    final avatar = AvatarData.parse(json, name: json['name'] as String);
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
      iconCode: avatar.iconCode,
      avatar: avatar,
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
    _avatar,
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

class ContactDeletePreview extends Equatable {
  const ContactDeletePreview({
    required this.debtRecords,
    required this.eventMembers,
    required this.linked,
  });
  final int debtRecords;
  final int eventMembers;
  final bool linked;

  factory ContactDeletePreview.fromJson(Map<String, dynamic> json) =>
      ContactDeletePreview(
        debtRecords: (json['debt_records'] as num?)?.toInt() ?? 0,
        eventMembers: (json['event_members'] as num?)?.toInt() ?? 0,
        linked: json['linked'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [debtRecords, eventMembers, linked];
}

class ContactDetail extends Equatable {
  const ContactDetail({
    required this.contact,
    this.unlinkedNames = const [],
    this.unlinkedNameCount = 0,
    this.unlinkedRecordCount = 0,
    this.deletePreview,
  });

  final Contact contact;
  final List<UnlinkedName> unlinkedNames;

  final int unlinkedNameCount;
  final int unlinkedRecordCount;

  final ContactDeletePreview? deletePreview;

  factory ContactDetail.fromJson(Map<String, dynamic> json) => ContactDetail(
    contact: Contact.fromJson(json),
    unlinkedNameCount:
        ((json['unlinked_total'] as Map?)?['names'] as num?)?.toInt() ?? 0,
    unlinkedRecordCount:
        ((json['unlinked_total'] as Map?)?['records'] as num?)?.toInt() ?? 0,
    deletePreview: json['delete_preview'] is Map<String, dynamic>
        ? ContactDeletePreview.fromJson(
            json['delete_preview'] as Map<String, dynamic>,
          )
        : null,
    unlinkedNames: ((json['unlinked_names'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(UnlinkedName.fromJson)
        .toList(),
  );

  @override
  List<Object?> get props => [
    contact,
    unlinkedNames,
    unlinkedNameCount,
    unlinkedRecordCount,
    deletePreview,
  ];
}

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

class SenderProfile extends Equatable {
  const SenderProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.iconCode,
    this.contactId,
    AvatarData? avatar,
  }) : _avatar = avatar;

  final String id;
  final String displayName;
  final String? email;
  final IconCode? iconCode;
  final String? contactId;
  final AvatarData? _avatar;

  /// 0.4.2 1b: the BE's avatar; built from the name + icon when absent.
  AvatarData get avatar =>
      _avatar ?? AvatarData.forName(displayName, iconCode: iconCode);

  factory SenderProfile.fromJson(Map<String, dynamic> json) {
    final name = json['display_name'] as String;
    final avatar = AvatarData.parse(json, name: name);
    return SenderProfile(
      id: json['id'] as String,
      displayName: name,
      email: json['email'] as String?,
      iconCode: avatar.iconCode,
      contactId: json['contact_id'] as String?,
      avatar: avatar,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    email,
    iconCode,
    contactId,
    _avatar,
  ];
}
