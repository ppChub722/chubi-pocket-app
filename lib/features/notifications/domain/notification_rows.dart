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
  /// A new shared bill with my part (split / event).
  billCreated,

  /// Someone edited a shared bill (split / event).
  billEdited,

  /// Someone deleted a shared bill.
  billDeleted,

  /// Any other type: its own words, no auto switch.
  other,
}

/// One row of the notification page (owner 2026-10-28, layout ก): a [แจ้ง]
/// switch that mutes [type], and, for a notice that asks something, an
/// [อัตโนมัติ] switch ([auto]) that answers it by itself.
///
/// The BE has ONE type for a new shared bill and ONE for an edit, whatever
/// the bill kind, so those two types show twice: in "บิลที่แชร์" with the
/// debts switch and in "อีเวนต์" with the events switch. The two rows of a
/// type share its mute value.
class NotificationRow {
  const NotificationRow({
    required this.type,
    required this.group,
    required this.kind,
    this.auto,
    this.autoMirror = false,
    this.mutable = true,
  });

  /// The BE type the แจ้ง switch mutes.
  final String type;
  final NotificationGroup group;
  final NotificationRowKind kind;

  /// The auto switch in this row; null = "–".
  final AutoSwitch? auto;

  /// The auto switch only mirrors another row's (shown, not flipped here).
  final bool autoMirror;

  /// False = requests: always on.
  final bool mutable;

  /// Unique on the page (a type can show in two groups).
  String get key => '${group.wire}-$type';

  /// Auto off = someone must answer, so the notice always comes (the BE
  /// delivers it even when muted): the แจ้ง switch is locked on.
  bool notifyLocked(AutoValues a) => auto != null && !a.of(auto!);

  /// The แจ้ง switch as shown.
  bool notifyOn(NotificationSettings s, AutoValues a) =>
      !mutable || notifyLocked(a) || !s.mutedTypes.contains(type);

  /// The แจ้ง switch can be flipped.
  bool notifyEditable(AutoValues a) => mutable && !notifyLocked(a);
}

const _created = {'shared_bill_created', 'split_created'};
const _edited = 'project_tx_changed';
const _deleted = 'shared_bill_deleted';

/// The page's rows, grouped in page order: the BE's types of each group, plus
/// the second row of the new-bill and edit types (see [NotificationRow]).
/// Requests come as ONE row (they can't be muted).
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
      if (g == NotificationGroup.event && created.isNotEmpty) {
        rows.add(
          NotificationRow(
            type: created,
            group: g,
            kind: NotificationRowKind.billCreated,
            auto: AutoSwitch.acceptEvents,
          ),
        );
      }
      for (final t in s.ofGroup(g)) {
        if (_created.contains(t.type)) {
          if (g == NotificationGroup.event) continue; // added above
          rows.add(
            NotificationRow(
              type: t.type,
              group: g,
              kind: NotificationRowKind.billCreated,
              auto: AutoSwitch.acceptDebts,
            ),
          );
          if (g == NotificationGroup.sharedBill && hasEdited) {
            rows.add(
              NotificationRow(
                type: _edited,
                group: g,
                kind: NotificationRowKind.billEdited,
                auto: AutoSwitch.syncDebts,
              ),
            );
          }
        } else if (t.type == _edited) {
          if (g == NotificationGroup.sharedBill) continue; // added above
          rows.add(
            NotificationRow(
              type: t.type,
              group: g,
              kind: NotificationRowKind.billEdited,
              auto: AutoSwitch.syncEvents,
            ),
          );
        } else if (t.type == _deleted) {
          rows.add(
            NotificationRow(
              type: t.type,
              group: g,
              kind: NotificationRowKind.billDeleted,
              auto: AutoSwitch.syncEvents,
              autoMirror: true,
            ),
          );
        } else {
          rows.add(
            NotificationRow(
              type: t.type,
              group: g,
              kind: NotificationRowKind.other,
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
