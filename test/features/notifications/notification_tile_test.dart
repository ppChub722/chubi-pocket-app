import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _n(
  NotificationType type, {
  Map<String, dynamic> payload = const {},
  DateTime? actionedAt,
}) => AppNotification(
  id: 'n1',
  recipientUserId: 'u1',
  type: type,
  payload: payload,
  createdAt: DateTime(2026, 10, 10),
  actionedAt: actionedAt,
);

void main() {
  // The dashboard's "ต้องจัดการ" lists what still shows answer buttons.
  test('awaitsAnswer: requests and one-tap actions until taken', () {
    expect(
      NotificationTile.awaitsAnswer(_n(NotificationType.contactLinkRequest)),
      isTrue,
    );
    expect(
      NotificationTile.awaitsAnswer(_n(NotificationType.splitPaid)),
      isTrue,
    );
    expect(
      NotificationTile.awaitsAnswer(
        _n(NotificationType.splitPaid, actionedAt: DateTime(2026, 10, 10)),
      ),
      isFalse,
    );
    // Informational — nothing to answer.
    expect(
      NotificationTile.awaitsAnswer(_n(NotificationType.splitReceived)),
      isFalse,
    );
  });

  test('awaitsAnswer: a change suggestion only with a copy to update', () {
    expect(
      NotificationTile.awaitsAnswer(_n(NotificationType.projectTxChanged)),
      isFalse,
    );
    expect(
      NotificationTile.awaitsAnswer(
        _n(
          NotificationType.projectTxChanged,
          payload: {
            'personal_transaction_id': 't1',
            'suggested': {'amount': 10},
          },
        ),
      ),
      isTrue,
    );
  });
}
