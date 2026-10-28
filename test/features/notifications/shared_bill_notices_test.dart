import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/notification_routes.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _notice(
  String type,
  Map<String, dynamic> payload,
  String? link,
) => AppNotification.fromJson({
  'id': 'n1',
  'type': type,
  'payload': payload,
  'deep_link': link,
  'state': 'unread',
  'awaits_answer': payload['applied'] == false,
  'created_at': '2026-10-27T10:00:00Z',
});

void main() {
  test('the 0.4.1-2 types parse from their wire names', () {
    for (final (wire, t) in [
      ('shared_bill_created', NotificationType.sharedBillCreated),
      ('shared_bill_deleted', NotificationType.sharedBillDeleted),
      ('shared_bill_disconnected', NotificationType.sharedBillDisconnected),
      ('event_completed', NotificationType.eventCompleted),
      ('event_member_removed', NotificationType.eventMemberRemoved),
    ]) {
      expect(NotificationType.fromWire(wire), t, reason: wire);
    }
  });

  test('a /event-bills deep link opens the bill form (its id); other links '
      'are pages', () {
    final bill = _notice('shared_bill_created', {
      'project_transaction_id': 'pt1',
      'applied': false,
    }, '/event-bills/pt1');
    expect(billOfLink(bill), 'pt1');

    final completed = _notice('event_completed', {
      'project_id': 'e1',
    }, '/projects/e1');
    expect(billOfLink(completed), isNull);
    expect(billOfLink(_notice('event_member_removed', {}, null)), isNull);
  });

  test('apply / disconnect answer: my copy tx id (null with no copy)', () {
    final made = MyBillCopyRef.fromJson({
      'my_copy': {
        'connected': true,
        'role': 'share',
        'transaction': {'id': 'tx1'},
      },
      'effects': <String, dynamic>{},
    });
    expect(made.transactionId, 'tx1');
    expect(made.connected, isTrue);

    final none = MyBillCopyRef.fromJson({'my_copy': null, 'effects': {}});
    expect(none.transactionId, isNull);
    expect(none.connected, isFalse);
  });
}
