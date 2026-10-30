import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/domain/notification_rows.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /notifications/settings` as the 0.4.2-3 BE answers (pageTypes order;
/// project_added retired, requests mutable).
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
            'mutable': true,
          },
      ],
      'auto_sync_events': true,
      'auto_sync_debts': true,
    });

void main() {
  test('rows: the new-bill and edit types are ONE row each in บิลที่แชร์ with '
      'an event and a split auto switch; each request is a row with its own '
      'auto switch (F2)', () {
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
      'event_completed:',
      'event_member_removed:',
    ]);
    expect(rows[NotificationGroup.recurring], hasLength(3));
    final requests = rows[NotificationGroup.request]!;
    expect(requests.map(line), [
      'project_invite:acceptEventInvites',
      'contact_link_request:acceptContactLinks',
      'account_invite:acceptWalletInvites',
    ]);
    expect(requests.every((r) => r.mutable), isTrue);
    // Every key is unique on the page.
    final keys = [for (final g in rows.values) ...g.map((r) => r.key)];
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('แจ้ง follows the mute only, whatever the auto switches (F1)', () {
    final s = _settings(muted: ['shared_bill_created', 'project_tx_changed']);
    final rows = notificationRows(s)[NotificationGroup.sharedBill]!;
    expect(rows.first.notifyOn(s), isFalse);
    expect(rows.first.mutable, isTrue);
    expect(rows[1].notifyOn(s), isFalse);
    expect(
      rows.last.notifyOn(_settings(muted: ['debt_disconnected'])),
      isFalse,
    );
    expect(rows.last.notifyOn(s), isTrue);
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
      expect(off.of(AutoSwitch.syncEvents), isFalse);
    },
  );
}
