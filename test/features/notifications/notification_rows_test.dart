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
  test('rows: the new-bill and edit types show in both groups with the '
      'kind\'s auto switch; requests are one row', () {
    final rows = notificationRows(_settings());
    String line(NotificationRow r) =>
        '${r.type}:${r.auto?.name ?? '-'}'
        '${r.autoMirror ? '(mirror)' : ''}';
    expect(rows[NotificationGroup.sharedBill]!.map(line), [
      'shared_bill_created:acceptDebts',
      'project_tx_changed:syncDebts',
      'shared_bill_deleted:syncDebts(mirror)',
      'shared_bill_disconnected:-',
      'debt_disconnected:-',
    ]);
    expect(rows[NotificationGroup.event]!.map(line), [
      'shared_bill_created:acceptEvents',
      'project_tx_changed:syncEvents',
      'project_added:-',
      'event_completed:-',
      'event_member_removed:-',
    ]);
    expect(rows[NotificationGroup.recurring], hasLength(3));
    final requests = rows[NotificationGroup.request]!.single;
    expect(requests.mutable, isFalse);
    // Every key is unique on the page.
    final keys = [for (final g in rows.values) ...g.map((r) => r.key)];
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('auto off locks แจ้ง on (even when muted); auto on + muted = off', () {
    final s = _settings(muted: ['shared_bill_created', 'project_tx_changed']);
    final rows = notificationRows(s);
    final splitNew = rows[NotificationGroup.sharedBill]!.first;
    final eventNew = rows[NotificationGroup.event]!.first;
    const a = AutoValues(
      acceptDebts: false,
      acceptEvents: true,
      syncDebts: true,
      syncEvents: true,
    );
    // Split bills: auto-accept off → asks → always delivered.
    expect(splitNew.notifyLocked(a), isTrue);
    expect(splitNew.notifyOn(s, a), isTrue);
    expect(splitNew.notifyEditable(a), isFalse);
    // Event bills: auto-accept on → muted = silent.
    expect(eventNew.notifyLocked(a), isFalse);
    expect(eventNew.notifyOn(s, a), isFalse);
    expect(eventNew.notifyEditable(a), isTrue);

    // A type without auto follows its mute; requests are always on.
    final unlinked = rows[NotificationGroup.sharedBill]!.last;
    expect(
      unlinked.notifyOn(_settings(muted: ['debt_disconnected']), _allOn),
      isFalse,
    );
    final requests = rows[NotificationGroup.request]!.single;
    expect(requests.notifyOn(s, _allOn), isTrue);
    expect(requests.notifyEditable(_allOn), isFalse);
  });

  test('the delete row mirrors the split update switch', () {
    final s = _settings();
    final deleted = notificationRows(s)[NotificationGroup.sharedBill]!
        .firstWhere((r) => r.type == 'shared_bill_deleted');
    const off = AutoValues(
      acceptDebts: true,
      acceptEvents: true,
      syncDebts: false,
      syncEvents: true,
    );
    expect(deleted.auto, AutoSwitch.syncDebts);
    expect(deleted.notifyLocked(off), isTrue);
    expect(deleted.notifyLocked(_allOn), isFalse);
  });
}
