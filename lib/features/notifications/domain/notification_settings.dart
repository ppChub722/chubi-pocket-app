import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import 'notification.dart';

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

/// The groups of the notification settings page, in page order.
enum NotificationGroup {
  sharedBill('shared_bill'),
  event('event'),
  recurring('recurring'),
  request('request');

  const NotificationGroup(this.wire);
  final String wire;

  static NotificationGroup? fromWire(String? s) =>
      values.where((g) => g.wire == s).firstOrNull;
}

/// One type row of the notification page, as the BE lists it.
class NotificationTypeSetting extends Equatable {
  const NotificationTypeSetting({
    required this.type,
    required this.group,
    required this.on,
    required this.mutable,
  });

  /// The wire type (`split_created`, `event_completed`, …).
  final String type;
  final NotificationGroup group;

  /// Not muted.
  final bool on;

  /// False = invites / link requests: always on.
  final bool mutable;

  NotificationTypeSetting withOn(bool on) => NotificationTypeSetting(
    type: type,
    group: group,
    on: on,
    mutable: mutable,
  );

  @override
  List<Object?> get props => [type, group, on, mutable];
}

/// `GET /notifications/settings` (0.4.1-2): on / off per type + the two
/// auto-sync switches (one value each, the same ones /users/me, the event
/// page and the person page show).
class NotificationSettings extends Equatable {
  const NotificationSettings({
    this.mutedTypes = const {},
    this.types = const [],
    this.autoSyncEvents = true,
    this.autoSyncDebts = true,
    this.defaultAccount,
  });

  final Set<String> mutedTypes;

  /// Every type the page lists, in page order (unknown groups dropped).
  final List<NotificationTypeSetting> types;
  final bool autoSyncEvents;
  final bool autoSyncDebts;

  /// The main wallet (กระเป๋าหลัก); the เงิน page sets it.
  final DefaultAccountRef? defaultAccount;

  bool isMuted(NotificationType t) => mutedTypes.contains(t.wire);

  /// [types] of [group], in page order.
  List<NotificationTypeSetting> ofGroup(NotificationGroup group) =>
      types.where((t) => t.group == group).toList();

  /// The muted list after turning [type] on / off.
  Set<String> mutedWith(String type, {required bool on}) =>
      on ? (mutedTypes.toSet()..remove(type)) : {...mutedTypes, type};

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final types = <NotificationTypeSetting>[];
    for (final raw in (json['types'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final group = NotificationGroup.fromWire(raw['group'] as String?);
      final type = raw['type'];
      if (group == null || type is! String) continue;
      types.add(
        NotificationTypeSetting(
          type: type,
          group: group,
          on: (raw['on'] as bool?) ?? true,
          mutable: (raw['mutable'] as bool?) ?? true,
        ),
      );
    }
    return NotificationSettings(
      mutedTypes: {
        ...((json['muted_types'] as List?) ?? const []).cast<String>(),
      },
      types: types,
      autoSyncEvents: (json['auto_sync_events'] as bool?) ?? true,
      autoSyncDebts: (json['auto_sync_debts'] as bool?) ?? true,
      defaultAccount: json['default_account'] is Map
          ? DefaultAccountRef.fromJson(
              (json['default_account'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  NotificationSettings copyWith({
    Set<String>? mutedTypes,
    bool? autoSyncEvents,
    bool? autoSyncDebts,
  }) {
    final muted = mutedTypes ?? this.mutedTypes;
    return NotificationSettings(
      mutedTypes: muted,
      types: [
        for (final t in types)
          t.mutable ? t.withOn(!muted.contains(t.type)) : t,
      ],
      autoSyncEvents: autoSyncEvents ?? this.autoSyncEvents,
      autoSyncDebts: autoSyncDebts ?? this.autoSyncDebts,
      defaultAccount: defaultAccount,
    );
  }

  @override
  List<Object?> get props => [
    mutedTypes,
    types,
    autoSyncEvents,
    autoSyncDebts,
    defaultAccount,
  ];
}
