import 'package:equatable/equatable.dart';

/// Notification trigger types — mirror of [`design/spec/13-notifications.md
/// §2`](../../../../../chubi-pocket-docs/design/spec/13-notifications.md).
/// Phase 1b ships 7 of these. `personal_debt_cancelled` is deferred to
/// Phase 2 per spec §2.7.
enum NotificationType {
  splitCreated('split_created'),

  /// The splitter changed or removed my share of their split (spec: BE
  /// contract 2026-10-10). Pending, one action "อัปเดตตาม" — unless a newer
  /// change superseded it (payload.superseded).
  splitChanged('split_changed'),
  splitPaid('split_paid'),
  splitReceived('split_received'),
  projectTxRecordedForYou('project_tx_recorded_for_you'),
  projectTxChanged('project_tx_changed'),
  projectInvite('project_invite'),
  contactLinkRequest('contact_link_request'),

  /// Shared-wallet invite (spec §14/4 + §14/8.1 — notification pattern,
  /// same as project member invites). Payload carries `account_id` +
  /// `account_name`; pending rows render inline Accept / Reject.
  accountInvite('account_invite'),

  /// "You were added to a project" (quick create, spec §10/4.24) —
  /// informational, mutable.
  projectAdded('project_added'),
  unknown('unknown');

  const NotificationType(this.wire);
  final String wire;

  static NotificationType fromWire(String s) {
    return NotificationType.values.firstWhere(
      (t) => t.wire == s,
      orElse: () => NotificationType.unknown,
    );
  }
}

/// One inbox row; payload is kept as a raw map — type-specific tiles read
/// the fields they care about. Audit columns aren't surfaced.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.actorUserId,
    this.actorDisplayName,
    this.deepLink,
    this.readAt,
    this.actionedAt,
    this.dismissedAt,
  });

  final String id;
  final String recipientUserId;
  final NotificationType type;

  /// Set when the action originated from a user (almost always). NULL for
  /// pure system events.
  final String? actorUserId;

  /// Hydrated by the BE list response — saves a separate users-cache lookup.
  final String? actorDisplayName;

  /// Trigger-specific shape. See spec §13.2.
  final Map<String, dynamic> payload;

  /// Optional client-routing hint set by the BE dispatcher. The shell's
  /// deep-link handler routes via `go_router` when present.
  final String? deepLink;

  final DateTime? readAt;
  final DateTime? actionedAt;
  final DateTime? dismissedAt;

  final DateTime createdAt;

  bool get isUnread => readAt == null;
  bool get isTerminal => actionedAt != null || dismissedAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      recipientUserId: json['recipient_user_id'] as String,
      type: NotificationType.fromWire(json['type'] as String),
      actorUserId: json['actor_user_id'] as String?,
      actorDisplayName: json['actor_display_name'] as String?,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      deepLink: json['deep_link'] as String?,
      readAt: _parseDate(json['read_at']),
      actionedAt: _parseDate(json['actioned_at']),
      dismissedAt: _parseDate(json['dismissed_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now().toUtc(),
    );
  }

  AppNotification copyWith({
    DateTime? readAt,
    DateTime? actionedAt,
    DateTime? dismissedAt,
  }) {
    return AppNotification(
      id: id,
      recipientUserId: recipientUserId,
      type: type,
      actorUserId: actorUserId,
      actorDisplayName: actorDisplayName,
      payload: payload,
      deepLink: deepLink,
      readAt: readAt ?? this.readAt,
      actionedAt: actionedAt ?? this.actionedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    recipientUserId,
    type,
    actorUserId,
    actorDisplayName,
    payload,
    deepLink,
    readAt,
    actionedAt,
    dismissedAt,
    createdAt,
  ];
}

DateTime? _parseDate(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}

/// Per-user notification preferences. One row per user; auto-seeded on
/// registration. See spec §13.1.
/// Per-user notification switches (contract §5). For each type the
/// recipient picks: receive it (not in [mutedTypes]) and run its action
/// automatically on arrival ([autoTypes]). A muted type ignores its auto
/// choice — kept, and back in force once it's unmuted.
class NotificationSettings extends Equatable {
  const NotificationSettings({
    required this.userId,
    this.mutedTypes = const {},
    this.autoTypes = const {},
    this.defaultAccountId,
    this.autoResolveOwnInProjects = false,
  });

  final String userId;
  final Set<String> mutedTypes;
  final Set<String> autoTypes;

  /// Wallet the "record receipt" auto-action uses; null = no wallet.
  final String? defaultAccountId;

  /// Rows I record myself in a project → my personal copy too.
  final bool autoResolveOwnInProjects;

  bool isMuted(NotificationType t) => mutedTypes.contains(t.wire);
  bool isAuto(NotificationType t) => autoTypes.contains(t.wire);

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    Set<String> set(String k) => {
      ...((json[k] as List?) ?? const []).cast<String>(),
    };
    return NotificationSettings(
      userId: json['user_id'] as String,
      mutedTypes: set('muted_types'),
      autoTypes: set('auto_types'),
      defaultAccountId: json['default_account_id'] as String?,
      autoResolveOwnInProjects:
          json['auto_resolve_own_in_projects'] as bool? ?? false,
    );
  }

  NotificationSettings copyWith({
    Set<String>? mutedTypes,
    Set<String>? autoTypes,
    String? defaultAccountId,
    bool clearDefaultAccount = false,
    bool? autoResolveOwnInProjects,
  }) {
    return NotificationSettings(
      userId: userId,
      mutedTypes: mutedTypes ?? this.mutedTypes,
      autoTypes: autoTypes ?? this.autoTypes,
      defaultAccountId: clearDefaultAccount
          ? null
          : (defaultAccountId ?? this.defaultAccountId),
      autoResolveOwnInProjects:
          autoResolveOwnInProjects ?? this.autoResolveOwnInProjects,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    mutedTypes,
    autoTypes,
    defaultAccountId,
    autoResolveOwnInProjects,
  ];
}
