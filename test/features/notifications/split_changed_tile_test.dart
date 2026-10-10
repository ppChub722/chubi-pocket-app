import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _changed({bool superseded = false, String change = 'amount'}) =>
    AppNotification(
      id: 'n1',
      recipientUserId: 'me',
      type: NotificationType.splitChanged,
      actorDisplayName: 'ปอนด์',
      createdAt: DateTime(2026, 10, 10, 14, 30),
      payload: {
        'split_id': 's1',
        'change': change,
        'splitter_display_name': 'ปอนด์',
        'old_amount': 150,
        'new_amount': change == 'removed' ? 0 : 120,
        'currency': 'THB',
        'description': 'ข้าวเย็น',
        'recipient_debt_id': 'd9',
        'superseded': ?(superseded ? true : null),
      },
    );

void main() {
  Future<void> pump(WidgetTester t, AppNotification n) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('th'),
      home: Scaffold(
        body: NotificationTile(
          notification: n,
          onTap: (_) {},
          onAccept: (_) {},
          onReject: (_) {},
        ),
      ),
    ),
  );

  testWidgets('split_changed: says what changed, offers "อัปเดตตาม"', (
    t,
  ) async {
    final n = _changed();
    await pump(t, n);
    expect(find.textContaining('ปอนด์ แก้ยอดหาร ข้าวเย็น'), findsOneWidget);
    expect(find.text('อัปเดตตาม'), findsOneWidget);
    expect(NotificationTile.awaitsAnswer(n), isTrue);
  });

  testWidgets('split_changed removed: its own wording', (t) async {
    await pump(t, _changed(change: 'removed'));
    expect(find.text('ปอนด์ เอาคุณออกจากการหาร ข้าวเย็น'), findsOneWidget);
  });

  testWidgets('a superseded split_changed has no button', (t) async {
    final n = _changed(superseded: true);
    await pump(t, n);
    expect(find.text('อัปเดตตาม'), findsNothing);
    expect(NotificationTile.awaitsAnswer(n), isFalse);
  });
}
