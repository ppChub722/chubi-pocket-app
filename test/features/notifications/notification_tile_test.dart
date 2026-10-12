import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  String type = 'split_paid',
  String state = 'unread',
  bool awaitsAnswer = true,
  Map<String, dynamic>? actor = const {
    'user_id': 'u2',
    'display_name': 'Aom',
    'icon_code': null,
  },
}) => {
  'id': 'n1',
  'type': type,
  'actor': actor,
  'payload': <String, dynamic>{},
  'deep_link': null,
  'state': state,
  'awaits_answer': awaitsAnswer,
  'read_at': null,
  'actioned_at': null,
  'dismissed_at': null,
  'created_at': '2026-10-10T00:00:00Z',
};

void main() {
  test('fromJson reads the v2 shape: actor, state, awaits_answer', () {
    final n = AppNotification.fromJson(_json());
    expect(n.actor?.userId, 'u2');
    expect(n.actor?.displayName, 'Aom');
    expect(n.state, NotificationState.unread);
    expect(n.isUnread, isTrue);
    expect(n.awaitsAnswer, isTrue);
  });

  test('a system event has no actor', () {
    final n = AppNotification.fromJson(_json(actor: null));
    expect(n.actor, isNull);
  });

  // The dashboard's "ต้องจัดการ" lists what the BE says still waits.
  test('awaitsAnswer follows the BE flag, not the type', () {
    expect(
      NotificationTile.awaitsAnswer(AppNotification.fromJson(_json())),
      isTrue,
    );
    expect(
      NotificationTile.awaitsAnswer(
        AppNotification.fromJson(_json(state: 'actioned', awaitsAnswer: false)),
      ),
      isFalse,
    );
    expect(
      NotificationTile.awaitsAnswer(
        AppNotification.fromJson(
          _json(type: 'split_received', awaitsAnswer: false),
        ),
      ),
      isFalse,
    );
  });

  test('state drives isActioned / isDismissed', () {
    final a = AppNotification.fromJson(_json(state: 'actioned'));
    expect(a.isActioned, isTrue);
    expect(a.isUnread, isFalse);
    expect(
      AppNotification.fromJson(_json(state: 'dismissed')).isDismissed,
      isTrue,
    );
  });

  test('settings: default_account is a ref, not an id', () {
    final s = NotificationSettings.fromJson({
      'muted_types': ['split_paid'],
      'auto_types': <String>[],
      'default_account': {'id': 'a1', 'name': 'KBank', 'icon_code': null},
      'auto_resolve_own_in_projects': true,
      'updated_at': '2026-10-10T00:00:00Z',
    });
    expect(s.defaultAccount?.id, 'a1');
    expect(s.defaultAccount?.name, 'KBank');
    expect(s.isMuted(NotificationType.splitPaid), isTrue);
    expect(
      NotificationSettings.fromJson({
        'muted_types': <String>[],
        'auto_types': <String>[],
        'default_account': null,
      }).defaultAccount,
      isNull,
    );
  });
}
