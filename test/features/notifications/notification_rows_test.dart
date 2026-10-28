import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/domain/notification_rows.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /notifications/settings` as the 0.4.1-2 BE answers (pageTypes order).
NotificationSettings _settings({List<String> muted = const []}) =>
    NotificationSettings.fromJson({
      'muted_types': muted,
      'types': [
        for (final (type, group) in const [
          ('shared_bill_created', 'shared_bill'),
          ('shared_bill_deleted', 'shared_bill'),
          ('shared_bill_disconnected', 'shared_bill'),
          ('debt_disconnected', 'shared_bill'),
          ('project_tx_changed', 'event'),
          ('project_added', 'event'),
          ('event_completed', 'event'),
          ('event_member_removed', 'event'),
          ('recurring_due', 'recurring'),
          ('recurring_ending', 'recurring'),
          ('recurring_auto_created', 'recurring'),
          ('project_invite', 'request'),
          ('contact_link_request', 'request'),
          ('account_invite', 'request'),
        ])
          {
            'type': type,
            'group': group,
            'on': !muted.contains(type),
            'mutable': group != 'request',
          },
      ],
      'auto_sync_events': true,
      'auto_sync_debts': true,
    });

const _allOn = AutoValues(
  acceptDebts: true,
  acceptEvents: true,
  syncDebts: true,
  syncEvents: true,
);

void main() {
  test('rows: the new-bill and edit types are ONE row each in บิลที่แชร์ with '
      'an event and a split auto switch; requests are one row', () {
    final rows = notificationRows(_settings());
    String line(NotificationRow r) =>
        '${r.type}:${r.autos.map((a) => a?.name ?? '-').join('|')}'
        '${r.autoMirror ? '(mirror)' : ''}';
    expect(rows[NotificationGroup.sharedBill]!.map(line), [
      'shared_bill_created:acceptEvents|acceptDebts',
      'project_tx_changed:syncEvents|syncDebts',
      'shared_bill_deleted:syncEvents|-(mirror)',
      'shared_bill_disconnected:-|-',
      'debt_disconnected:-|-',
    ]);
    // No auto columns outside บิลที่แชร์; the edit type isn't repeated.
    expect(rows[NotificationGroup.event]!.map(line), [
      'project_added:',
      'event_completed:',
      'event_member_removed:',
    ]);
    expect(rows[NotificationGroup.recurring], hasLength(3));
    final requests = rows[NotificationGroup.request]!.single;
    expect(requests.mutable, isFalse);
    expect(requests.autos, isEmpty);
    // Every key is unique on the page.
    final keys = [for (final g in rows.values) ...g.map((r) => r.key)];
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('any auto switch off locks แจ้ง on (even when muted); all on + muted '
      '= off', () {
    final s = _settings(muted: ['shared_bill_created', 'project_tx_changed']);
    final rows = notificationRows(s)[NotificationGroup.sharedBill]!;
    final created = rows.first;
    final edited = rows[1];
    const splitOff = AutoValues(
      acceptDebts: false,
      acceptEvents: true,
      syncDebts: true,
      syncEvents: true,
    );
    // Split auto-accept off → asks → always delivered.
    expect(created.notifyLocked(splitOff), isTrue);
    expect(created.notifyOn(s, splitOff), isTrue);
    expect(created.notifyEditable(splitOff), isFalse);
    // Both update switches on → muted = silent.
    expect(edited.notifyLocked(splitOff), isFalse);
    expect(edited.notifyOn(s, splitOff), isFalse);
    expect(edited.notifyEditable(splitOff), isTrue);

    // A type without auto follows its mute; requests are always on.
    final unlinked = rows.last;
    expect(
      unlinked.notifyOn(_settings(muted: ['debt_disconnected']), _allOn),
      isFalse,
    );
    final requests = notificationRows(s)[NotificationGroup.request]!.single;
    expect(requests.notifyOn(s, _allOn), isTrue);
    expect(requests.notifyEditable(_allOn), isFalse);
  });

  test(
    'the delete row mirrors the event update switch (event-bill deletes follow it)',
    () {
      final deleted =
          notificationRows(_settings())[NotificationGroup.sharedBill]!
              .firstWhere((r) => r.type == 'shared_bill_deleted');
      const off = AutoValues(
        acceptDebts: true,
        acceptEvents: true,
        syncDebts: true,
        syncEvents: false,
      );
      expect(deleted.autos, [AutoSwitch.syncEvents, null]);
      expect(deleted.autoMirror, isTrue);
      expect(deleted.notifyLocked(off), isTrue);
      expect(deleted.notifyLocked(_allOn), isFalse);
    },
  );
}
