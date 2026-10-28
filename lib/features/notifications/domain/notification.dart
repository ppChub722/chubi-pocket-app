import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';

export 'notification_settings.dart';

enum NotificationType {
  splitCreated('split_created'),

  splitChanged('split_changed'),

  /// 0.4.1-1 D9: the other side disconnected a linked debt (info only;
  /// payload person_name / amount / direction, deep link to my entry).
  debtDisconnected('debt_disconnected'),
  projectTxRecordedForYou('project_tx_recorded_for_you'),
  projectTxChanged('project_tx_changed'),
  projectInvite('project_invite'),
  contactLinkRequest('contact_link_request'),

  accountInvite('account_invite'),

  projectAdded('project_added'),

  recurringDue('recurring_due'),

  recurringEnding('recurring_ending'),

  /// The day's tx the auto-create recorded (one notice per day).
  recurringAutoCreated('recurring_auto_created'),

  /// 0.4.1-2: another member saved a shared bill I have a part in; replaces
  /// project_tx_recorded_for_you. `applied` false = "เพิ่มในสมุด" asks.
  sharedBillCreated('shared_bill_created'),

  /// A shared bill I hold a copy of was deleted; `applied` false (event
  /// bill, my switch off) = "ลบตาม" asks, else info.
  sharedBillDeleted('shared_bill_deleted'),

  /// Another member disconnected their copy of a split bill (info).
  sharedBillDisconnected('shared_bill_disconnected'),

  /// The owner completed an event I'm in: locked, no more sync (info).
  eventCompleted('event_completed'),

  /// The owner removed me from an event; my records stay, plain (info).
  eventMemberRemoved('event_member_removed'),
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

class NotificationActor extends Equatable {
  const NotificationActor({
    required this.userId,
    required this.displayName,
    this.iconCode,
  });

  final String userId;
  final String displayName;
  final IconCode? iconCode;

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      iconCode: json['icon_code'] is Map
          ? IconCode.fromJson(
              (json['icon_code'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [userId, displayName, iconCode];
}

enum NotificationState {
  unread,
  read,
  actioned,
  dismissed;

  static NotificationState fromWire(String? s) => values.firstWhere(
    (v) => v.name == s,
    orElse: () => NotificationState.unread,
  );
}

class InboxSummary extends Equatable {
  const InboxSummary({
    this.all = 0,
    this.needsAnswer = 0,
    this.unread = 0,
    this.dismissed = 0,
  });

  final int all;
  final int needsAnswer;
  final int unread;
  final int dismissed;

  factory InboxSummary.fromJson(Map<String, dynamic>? json) => InboxSummary(
    all: (json?['all'] as num?)?.toInt() ?? 0,
    needsAnswer: (json?['needs_answer'] as num?)?.toInt() ?? 0,
    unread: (json?['unread'] as num?)?.toInt() ?? 0,
    dismissed: (json?['dismissed'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [all, needsAnswer, unread, dismissed];
}

class Badges extends Equatable {
  const Badges({
    required this.unreadNotifications,
    required this.pendingDrafts,
  });

  final int unreadNotifications;
  final int pendingDrafts;

  factory Badges.fromJson(Map<String, dynamic> json) => Badges(
    unreadNotifications: (json['unread_notifications'] as num?)?.toInt() ?? 0,
    pendingDrafts: (json['pending_drafts'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [unreadNotifications, pendingDrafts];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.state = NotificationState.unread,
    this.awaitsAnswer = false,
    this.actor,
    this.deepLink,
    this.readAt,
    this.actionedAt,
    this.dismissedAt,
  });

  final String id;
  final NotificationType type;

  final NotificationActor? actor;

  final Map<String, dynamic> payload;

  final String? deepLink;

  final NotificationState state;

  final bool awaitsAnswer;

  final DateTime? readAt;
  final DateTime? actionedAt;
  final DateTime? dismissedAt;

  final DateTime createdAt;

  bool get isUnread => state == NotificationState.unread;
  bool get isActioned => state == NotificationState.actioned;
  bool get isDismissed => state == NotificationState.dismissed;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.fromWire(json['type'] as String),
      actor: json['actor'] is Map
          ? NotificationActor.fromJson(
              (json['actor'] as Map).cast<String, dynamic>(),
            )
          : null,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      deepLink: json['deep_link'] as String?,
      state: NotificationState.fromWire(json['state'] as String?),
      awaitsAnswer: json['awaits_answer'] as bool? ?? false,
      readAt: _parseDate(json['read_at']),
      actionedAt: _parseDate(json['actioned_at']),
      dismissedAt: _parseDate(json['dismissed_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now().toUtc(),
    );
  }

  AppNotification asActioned(DateTime at) => AppNotification(
    id: id,
    type: type,
    payload: payload,
    createdAt: createdAt,
    state: NotificationState.actioned,
    awaitsAnswer: false,
    actor: actor,
    deepLink: deepLink,
    readAt: readAt ?? at,
    actionedAt: at,
    dismissedAt: dismissedAt,
  );

  AppNotification asRead(DateTime at) => AppNotification(
    id: id,
    type: type,
    payload: payload,
    createdAt: createdAt,
    state: NotificationState.read,
    awaitsAnswer: awaitsAnswer,
    actor: actor,
    deepLink: deepLink,
    readAt: at,
    actionedAt: actionedAt,
    dismissedAt: dismissedAt,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    actor,
    payload,
    deepLink,
    state,
    awaitsAnswer,
    readAt,
    actionedAt,
    dismissedAt,
    createdAt,
  ];
}

class NotificationActionResult {
  const NotificationActionResult({
    required this.notification,
    required this.badges,
    this.summary = const InboxSummary(),
  });

  final AppNotification notification;
  final Badges badges;
  final InboxSummary summary;

  factory NotificationActionResult.fromJson(Map<String, dynamic> json) =>
      NotificationActionResult(
        notification: AppNotification.fromJson(
          json['notification'] as Map<String, dynamic>,
        ),
        badges: Badges.fromJson(
          (json['badges'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        summary: InboxSummary.fromJson(
          (json['summary'] as Map?)?.cast<String, dynamic>(),
        ),
      );
}

class InboxCounts {
  const InboxCounts({required this.badges, required this.summary});

  final Badges badges;
  final InboxSummary summary;

  factory InboxCounts.fromJson(Map<String, dynamic> json) => InboxCounts(
    badges: Badges.fromJson(
      (json['badges'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    summary: InboxSummary.fromJson(
      (json['summary'] as Map?)?.cast<String, dynamic>(),
    ),
  );
}

DateTime? _parseDate(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}
