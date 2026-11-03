import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/notification_routes.dart';
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
  test('the bill and event types parse from their wire names', () {
    for (final (wire, t) in [
      ('bill_invite', NotificationType.billInvite),
      ('bill_new', NotificationType.billNew),
      ('bill_changed', NotificationType.billChanged),
      ('bill_removed', NotificationType.billRemoved),
      ('bill_owner_changed', NotificationType.billOwnerChanged),
      ('bill_moved', NotificationType.billMoved),
      ('debt_repaid', NotificationType.debtRepaid),
      ('event_completed', NotificationType.eventCompleted),
      ('event_member_removed', NotificationType.eventMemberRemoved),
      ('event_deleted', NotificationType.eventDeleted),
      ('shared_bill_created', NotificationType.unknown),
    ]) {
      expect(NotificationType.fromWire(wire), t, reason: wire);
    }
  });

  test('a bill deep link opens the bill form; other links are pages', () {
    final event = _notice('bill_new', {}, '/projects/e1/bills/p1');
    expect(billOfLink(event), (id: 'p1', projectId: 'e1'));

    final split = _notice('bill_invite', {}, '/split-bills/p2');
    expect(billOfLink(split), (id: 'p2', projectId: null));

    final completed = _notice('event_completed', {
      'project_id': 'e1',
    }, '/projects/e1');
    expect(billOfLink(completed), isNull);
    expect(billOfLink(_notice('event_member_removed', {}, null)), isNull);
  });
}
