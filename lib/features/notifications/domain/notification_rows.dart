import 'notification_settings.dart';

/// The four account auto switches (one value each, on `/users/me`; the
/// event and person pages show the same ones).
enum AutoSwitch { acceptDebts, acceptEvents, syncDebts, syncEvents }

/// The signed-in user's four auto switches.
class AutoValues {
  const AutoValues({
    required this.acceptDebts,
    required this.acceptEvents,
    required this.syncDebts,
    required this.syncEvents,
  });

  final bool acceptDebts;
  final bool acceptEvents;
  final bool syncDebts;
  final bool syncEvents;

  bool of(AutoSwitch s) => switch (s) {
    AutoSwitch.acceptDebts => acceptDebts,
    AutoSwitch.acceptEvents => acceptEvents,
    AutoSwitch.syncDebts => syncDebts,
    AutoSwitch.syncEvents => syncEvents,
  };
}

/// What a row is about, for its words.
enum NotificationRowKind {
  /// A new shared bill with my part (event or split).
  billCreated,

  /// Someone edited a shared bill (event or split).
  billEdited,

  /// Someone deleted a shared bill.
  billDeleted,

  /// Any other type: its own words, no auto switch.
  other,
}

/// The auto columns of the "บิลที่แชร์" card, in order: อีเวนต์, แบ่งจ่าย.
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

  /// False = requests: always on.
  final bool mutable;

  /// Unique on the page.
  String get key => '${group.wire}-$type';

  /// The auto switches this row shows.
  Iterable<AutoSwitch> get shownAutos => autos.whereType<AutoSwitch>();

  /// The แจ้ง switch as shown: independent of the auto switches (F1).
  bool notifyOn(NotificationSettings s) =>
      !mutable || !s.mutedTypes.contains(type);
}

const _created = {'shared_bill_created', 'split_created'};
const _edited = 'project_tx_changed';
const _deleted = 'shared_bill_deleted';

/// The page's rows, grouped in page order. The new-bill and edit types are
/// ONE row each in "บิลที่แชร์" (whatever group the BE lists them in), with
/// the event and split auto switches side by side. Requests come as ONE row
/// (they can't be muted).
Map<NotificationGroup, List<NotificationRow>> notificationRows(
  NotificationSettings s,
) {
  final types = {for (final t in s.types) t.type};
  final created = types.firstWhere(_created.contains, orElse: () => '');
  final hasEdited = types.contains(_edited);
  final out = <NotificationGroup, List<NotificationRow>>{};
  for (final g in NotificationGroup.values) {
    final rows = <NotificationRow>[];
    if (g == NotificationGroup.request) {
      if (s.ofGroup(g).isNotEmpty) {
        rows.add(
          NotificationRow(
            type: s.ofGroup(g).first.type,
            group: g,
            kind: NotificationRowKind.other,
            mutable: false,
          ),
        );
      }
    } else {
      final shared = g == NotificationGroup.sharedBill;
      if (shared) {
        if (created.isNotEmpty) {
          rows.add(
            NotificationRow(
              type: created,
              group: g,
              kind: NotificationRowKind.billCreated,
              autos: const [AutoSwitch.acceptEvents, AutoSwitch.acceptDebts],
            ),
          );
        }
        if (hasEdited) {
          rows.add(
            NotificationRow(
              type: _edited,
              group: g,
              kind: NotificationRowKind.billEdited,
              autos: const [AutoSwitch.syncEvents, AutoSwitch.syncDebts],
            ),
          );
        }
      }
      for (final t in s.ofGroup(g)) {
        // Shown once, in "บิลที่แชร์" (above).
        if (_created.contains(t.type) || t.type == _edited) continue;
        if (t.type == _deleted) {
          // Event-bill deletes follow the event update switch; a deleted split
          // bill always leaves my copy as a plain tx (nothing to choose).
          rows.add(
            NotificationRow(
              type: t.type,
              group: g,
              kind: NotificationRowKind.billDeleted,
              autos: const [AutoSwitch.syncEvents, null],
              autoMirror: true,
            ),
          );
        } else {
          rows.add(
            NotificationRow(
              type: t.type,
              group: g,
              kind: NotificationRowKind.other,
              autos: shared ? const [null, null] : const [],
              mutable: t.mutable,
            ),
          );
        }
      }
    }
    if (rows.isNotEmpty) out[g] = rows;
  }
  return out;
}
