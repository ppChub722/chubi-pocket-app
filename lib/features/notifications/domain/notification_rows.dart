import 'notification_settings.dart';

/// The account auto switches (one value each, on `/users/me`; the event,
/// person, contacts and wallets pages show the same ones). The last three
/// answer a request by themselves (F2).
enum AutoSwitch {
  acceptDebts,
  acceptEvents,
  syncDebts,
  syncEvents,
  acceptEventInvites,
  acceptContactLinks,
  acceptWalletInvites,
}

/// The signed-in user's auto switches.
class AutoValues {
  const AutoValues({
    required this.acceptDebts,
    required this.acceptEvents,
    required this.syncDebts,
    required this.syncEvents,
    this.acceptEventInvites = false,
    this.acceptContactLinks = false,
    this.acceptWalletInvites = false,
  });

  final bool acceptDebts;
  final bool acceptEvents;
  final bool syncDebts;
  final bool syncEvents;
  final bool acceptEventInvites;
  final bool acceptContactLinks;
  final bool acceptWalletInvites;

  bool of(AutoSwitch s) => switch (s) {
    AutoSwitch.acceptDebts => acceptDebts,
    AutoSwitch.acceptEvents => acceptEvents,
    AutoSwitch.syncDebts => syncDebts,
    AutoSwitch.syncEvents => syncEvents,
    AutoSwitch.acceptEventInvites => acceptEventInvites,
    AutoSwitch.acceptContactLinks => acceptContactLinks,
    AutoSwitch.acceptWalletInvites => acceptWalletInvites,
  };

  /// These values with [s] set to [on].
  AutoValues withSwitch(AutoSwitch s, bool on) => AutoValues(
    acceptDebts: s == AutoSwitch.acceptDebts ? on : acceptDebts,
    acceptEvents: s == AutoSwitch.acceptEvents ? on : acceptEvents,
    syncDebts: s == AutoSwitch.syncDebts ? on : syncDebts,
    syncEvents: s == AutoSwitch.syncEvents ? on : syncEvents,
    acceptEventInvites: s == AutoSwitch.acceptEventInvites
        ? on
        : acceptEventInvites,
    acceptContactLinks: s == AutoSwitch.acceptContactLinks
        ? on
        : acceptContactLinks,
    acceptWalletInvites: s == AutoSwitch.acceptWalletInvites
        ? on
        : acceptWalletInvites,
  );
}

/// A request type's own auto-accept switch (F2); null = not a request.
AutoSwitch? requestSwitchOf(String type) => switch (type) {
  'project_invite' => AutoSwitch.acceptEventInvites,
  'contact_link_request' => AutoSwitch.acceptContactLinks,
  'account_invite' => AutoSwitch.acceptWalletInvites,
  _ => null,
};

/// What a row is about, for its words.
enum NotificationRowKind {
  /// A new shared bill with my part (event or split).
  billCreated,

  /// Someone edited a shared bill (event or split).
  billEdited,

  /// Any other type: its own words, no auto switch.
  other,
}

/// The auto columns of the "บิลที่แชร์" card, in order: อีเวนต์, แบ่งจ่าย.
/// The requests card has one: อัตโนมัติ.
const autoColumns = 2;

/// One row of the notification page (owner 2026-10-28): a [แจ้ง] switch that
/// mutes [type], then the card's auto columns.
///
/// The BE has ONE type for a new shared bill and ONE for an edit, whatever
/// the bill kind, so each shows as ONE row (owner: "รวมเลย") with an auto
/// switch per kind: อีเวนต์ | แบ่งจ่าย. Rows of the other cards have no auto
/// columns.
class NotificationRow {
  const NotificationRow({
    required this.type,
    required this.group,
    required this.kind,
    this.autos = const [],
    this.autoMirror = false,
    this.mutable = true,
  });

  /// The BE type the แจ้ง switch mutes.
  final String type;
  final NotificationGroup group;
  final NotificationRowKind kind;

  /// One entry per auto column of the card; null = blank. Empty = the card has
  /// no auto columns.
  final List<AutoSwitch?> autos;

  /// The auto switches only mirror another row's (shown, not flipped here).
  final bool autoMirror;

  /// False = the BE says it can't be muted (always on).
  final bool mutable;

  /// Unique on the page.
  String get key => '${group.wire}-$type';

  /// The auto switches this row shows.
  Iterable<AutoSwitch> get shownAutos => autos.whereType<AutoSwitch>();

  /// The แจ้ง switch as shown: independent of the auto switches (F1).
  bool notifyOn(NotificationSettings s) =>
      !mutable || !s.mutedTypes.contains(type);
}

/// The page's rows, grouped in page order, as the BE lists them. In "บิลที่
/// แชร์" a new bill and an edited one carry the event and split auto switches
/// side by side. Each request is its own row with its own auto-accept switch
/// (F2).
Map<NotificationGroup, List<NotificationRow>> notificationRows(
  NotificationSettings s,
) {
  final out = <NotificationGroup, List<NotificationRow>>{};
  for (final g in NotificationGroup.values) {
    final shared = g == NotificationGroup.sharedBill;
    final rows = [
      for (final t in s.ofGroup(g))
        NotificationRow(
          type: t.type,
          group: g,
          kind: switch (t.type) {
            'bill_new' => NotificationRowKind.billCreated,
            'bill_changed' => NotificationRowKind.billEdited,
            _ => NotificationRowKind.other,
          },
          autos: switch (t.type) {
            _ when g == NotificationGroup.request => [requestSwitchOf(t.type)],
            'bill_new' => const [
              AutoSwitch.acceptEvents,
              AutoSwitch.acceptDebts,
            ],
            'bill_changed' => const [
              AutoSwitch.syncEvents,
              AutoSwitch.syncDebts,
            ],
            _ => shared ? const [null, null] : const [],
          },
          mutable: t.mutable,
        ),
    ];
    if (rows.isNotEmpty) out[g] = rows;
  }
  return out;
}
