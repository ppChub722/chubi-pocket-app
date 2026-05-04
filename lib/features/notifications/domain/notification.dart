import 'package:equatable/equatable.dart';

/// Notification trigger types — mirror of [`design/spec/13-notifications.md
/// §2`](../../../../../chubi-pocket-docs/design/spec/13-notifications.md).
/// Phase 1b ships 7 of these. `personal_debt_cancelled` is deferred to
/// Phase 2 per spec §2.7.
enum NotificationType {
  splitCreated('split_created'),
  splitPaid('split_paid'),
  splitReceived('split_received'),
  projectTxRecordedForYou('project_tx_recorded_for_you'),
  projectTxChanged('project_tx_changed'),
  projectInvite('project_invite'),
  contactLinkRequest('contact_link_request'),
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

/// One inbox row. Payload is kept as a raw map — type-specific tiles read
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
class NotificationSettings extends Equatable {
  const NotificationSettings({
    required this.userId,
    required this.autoNotifyLinkedSplitContacts,
    required this.autoAddToPersonalDebtOnSplitNotification,
    required this.autoRecordReceivedPayment,
    required this.autoResolveOwnInProjects,
    this.defaultAccountId,
  });

  final String userId;
  final bool autoNotifyLinkedSplitContacts;
  final bool autoAddToPersonalDebtOnSplitNotification;
  final bool autoRecordReceivedPayment;
  final bool autoResolveOwnInProjects;
  final String? defaultAccountId;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['user_id'] as String,
      autoNotifyLinkedSplitContacts:
          json['auto_notify_linked_split_contacts'] as bool? ?? true,
      autoAddToPersonalDebtOnSplitNotification:
          json['auto_add_to_personal_debt_on_split_notification'] as bool? ??
              false,
      autoRecordReceivedPayment:
          json['auto_record_received_payment'] as bool? ?? false,
      autoResolveOwnInProjects:
          json['auto_resolve_own_in_projects'] as bool? ?? false,
      defaultAccountId: json['default_account_id'] as String?,
    );
  }

  NotificationSettings copyWith({
    bool? autoNotifyLinkedSplitContacts,
    bool? autoAddToPersonalDebtOnSplitNotification,
    bool? autoRecordReceivedPayment,
    bool? autoResolveOwnInProjects,
    String? defaultAccountId,
  }) {
    return NotificationSettings(
      userId: userId,
      autoNotifyLinkedSplitContacts:
          autoNotifyLinkedSplitContacts ?? this.autoNotifyLinkedSplitContacts,
      autoAddToPersonalDebtOnSplitNotification:
          autoAddToPersonalDebtOnSplitNotification ??
              this.autoAddToPersonalDebtOnSplitNotification,
      autoRecordReceivedPayment:
          autoRecordReceivedPayment ?? this.autoRecordReceivedPayment,
      autoResolveOwnInProjects:
          autoResolveOwnInProjects ?? this.autoResolveOwnInProjects,
      defaultAccountId: defaultAccountId ?? this.defaultAccountId,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        autoNotifyLinkedSplitContacts,
        autoAddToPersonalDebtOnSplitNotification,
        autoRecordReceivedPayment,
        autoResolveOwnInProjects,
        defaultAccountId,
      ];
}
