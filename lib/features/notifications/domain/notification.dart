import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';

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

  /// Recurring items fell due and wait as drafts (owner 2026-10-13): ONE
  /// grouped notice while unread, payload {count}, deep link /pending.
  recurringDue('recurring_due'),

  /// A recurring has few upcoming items left: payload {recurring_id, name,
  /// left}, deep link /recurring/{id}.
  recurringEnding('recurring_ending'),
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

/// Who triggered a notification (API `UserRef`).
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

/// Computed by the BE (actioned > dismissed > read > unread).
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

/// App-wide counters returned by every notification write (API `Badges`).
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

/// One inbox row; payload is kept as a raw map — type-specific tiles read
/// the fields they care about (names inside are resolved by the BE).
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

  /// Set when the action originated from a user (almost always). NULL for
  /// pure system events.
  final NotificationActor? actor;

  /// Trigger-specific shape. See spec §13.2.
  final Map<String, dynamic> payload;

  /// Optional client-routing hint set by the BE dispatcher. The shell's
  /// deep-link handler routes via `go_router` when present.
  final String? deepLink;

  final NotificationState state;

  /// The BE's call: the row still waits for the user (a request or a
  /// one-tap action not yet taken) and shows its answer buttons.
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

  /// Local flip for bulk "mark all read" (the BE has already done it).
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

/// A write's reply (read / actioned / dismiss): the row in its new state +
/// the fresh badges.
class NotificationActionResult {
  const NotificationActionResult({
    required this.notification,
    required this.badges,
  });

  final AppNotification notification;
  final Badges badges;
}

DateTime? _parseDate(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}

/// The wallet the "record receipt" auto-action writes into (API
/// `AccountRef`, trimmed to what the settings row shows).
class DefaultAccountRef extends Equatable {
  const DefaultAccountRef({
    required this.id,
    required this.name,
    this.iconCode,
  });

  final String id;
  final String name;
  final IconCode? iconCode;

  factory DefaultAccountRef.fromJson(Map<String, dynamic> json) {
    return DefaultAccountRef(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['icon_code'] is Map
          ? IconCode.fromJson(
              (json['icon_code'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, iconCode];
}

/// Per-user notification switches (contract §5). For each type the
/// recipient picks: receive it (not in [mutedTypes]) and run its action
/// automatically on arrival ([autoTypes]). A muted type ignores its auto
/// choice — kept, and back in force once it's unmuted.
class NotificationSettings extends Equatable {
  const NotificationSettings({
    this.mutedTypes = const {},
    this.autoTypes = const {},
    this.defaultAccount,
    this.autoResolveOwnInProjects = false,
  });

  final Set<String> mutedTypes;
  final Set<String> autoTypes;

  /// Wallet the "record receipt" auto-action uses; null = no wallet.
  final DefaultAccountRef? defaultAccount;

  /// Rows I record myself in a project → my personal copy too.
  final bool autoResolveOwnInProjects;

  bool isMuted(NotificationType t) => mutedTypes.contains(t.wire);
  bool isAuto(NotificationType t) => autoTypes.contains(t.wire);

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    Set<String> set(String k) => {
      ...((json[k] as List?) ?? const []).cast<String>(),
    };
    return NotificationSettings(
      mutedTypes: set('muted_types'),
      autoTypes: set('auto_types'),
      defaultAccount: json['default_account'] is Map
          ? DefaultAccountRef.fromJson(
              (json['default_account'] as Map).cast<String, dynamic>(),
            )
          : null,
      autoResolveOwnInProjects:
          json['auto_resolve_own_in_projects'] as bool? ?? false,
    );
  }

  NotificationSettings copyWith({
    Set<String>? mutedTypes,
    Set<String>? autoTypes,
    DefaultAccountRef? defaultAccount,
    bool clearDefaultAccount = false,
    bool? autoResolveOwnInProjects,
  }) {
    return NotificationSettings(
      mutedTypes: mutedTypes ?? this.mutedTypes,
      autoTypes: autoTypes ?? this.autoTypes,
      defaultAccount: clearDefaultAccount
          ? null
          : (defaultAccount ?? this.defaultAccount),
      autoResolveOwnInProjects:
          autoResolveOwnInProjects ?? this.autoResolveOwnInProjects,
    );
  }

  @override
  List<Object?> get props => [
    mutedTypes,
    autoTypes,
    defaultAccount,
    autoResolveOwnInProjects,
  ];
}
