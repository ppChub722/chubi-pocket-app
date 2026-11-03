import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/domain/notification_rows.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /notifications/settings` as the paper-model BE answers (pageTypes
/// order, every type mutable).
NotificationSettings _settings({List<String> muted = const []}) =>
    NotificationSettings.fromJson({
      'muted_types': muted,
      'types': [
        for (final (type, group) in const [
          ('bill_invite', 'bill'),
          ('bill_new', 'bill'),
          ('bill_changed', 'bill'),
          ('bill_removed', 'bill'),
          ('bill_owner_changed', 'bill'),
          ('bill_moved', 'bill'),
          ('debt_repaid', 'debt'),
          ('debt_disconnected', 'debt'),
          ('event_completed', 'event'),
          ('event_member_removed', 'event'),
          ('event_deleted', 'event'),
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
  test('rows: a new bill and an edited one carry the event and split auto '
      'switches; each request is a row with its own auto switch (F2)', () {
    final rows = notificationRows(_settings());
    String line(NotificationRow r) =>
        '${r.type}:${r.autos.map((a) => a?.name ?? '-').join('|')}';
    expect(rows[NotificationGroup.sharedBill]!.map(line), [
      'bill_invite:-|-',
      'bill_new:acceptEvents|acceptDebts',
      'bill_changed:syncEvents|syncDebts',
      'bill_removed:-|-',
      'bill_owner_changed:-|-',
      'bill_moved:-|-',
    ]);
    expect(rows[NotificationGroup.debt]!.map(line), [
      'debt_repaid:',
      'debt_disconnected:',
    ]);
    expect(rows[NotificationGroup.event], hasLength(3));
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
    final s = _settings(muted: ['bill_new', 'bill_changed']);
    final rows = notificationRows(s)[NotificationGroup.sharedBill]!;
    expect(rows[1].notifyOn(s), isFalse);
    expect(rows[1].mutable, isTrue);
    expect(rows[2].notifyOn(s), isFalse);
    expect(rows.first.notifyOn(s), isTrue);
  });
}
