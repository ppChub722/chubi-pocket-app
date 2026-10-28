import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/notifications/data/notifications_repository.dart';
import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /notifications/settings` as the 0.4.1-2 BE answers (BE-3 spec).
Map<String, dynamic> _settingsJson({
  List<String> muted = const ['split_changed'],
}) => {
  'muted_types': muted,
  'types': [
    for (final (type, group, mutable) in [
      ('split_created', 'shared_bill', true),
      ('split_changed', 'shared_bill', true),
      ('debt_disconnected', 'shared_bill', true),
      ('project_tx_changed', 'event', true),
      ('recurring_due', 'recurring', true),
      ('project_invite', 'request', false),
      ('some_future_type', 'later_group', true),
    ])
      {
        'type': type,
        'group': group,
        'on': !muted.contains(type),
        'mutable': mutable,
      },
  ],
  'auto_sync_events': true,
  'auto_sync_debts': false,
  'default_account': {'id': 'a1', 'name': 'KBank', 'icon_code': null},
  'updated_at': '2026-10-27T00:00:00Z',
};

class _Repo extends Fake implements NotificationsRepository {
  _Repo({required this.fail});

  final bool fail;
  var settings = NotificationSettings.fromJson(_settingsJson());
  final puts = <Set<String>?>[];

  @override
  Future<NotificationSettings> getSettings() async => settings;

  @override
  Future<NotificationSettings> updateSettings({
    Set<String>? mutedTypes,
    bool? autoSyncEvents,
    bool? autoSyncDebts,
  }) async {
    puts.add(mutedTypes);
    if (fail) {
      throw const ApiException(code: 'INTERNAL', message: 'boom');
    }
    return settings = NotificationSettings.fromJson(
      _settingsJson(muted: mutedTypes!.toList()),
    );
  }
}

void main() {
  test('settings parse the prod shape: groups in page order, switches', () {
    final s = NotificationSettings.fromJson(_settingsJson());
    expect(s.autoSyncEvents, isTrue);
    expect(s.autoSyncDebts, isFalse);
    expect(s.defaultAccount?.name, 'KBank');
    expect(s.ofGroup(NotificationGroup.sharedBill).map((t) => t.type), [
      'split_created',
      'split_changed',
      'debt_disconnected',
    ]);
    expect(s.ofGroup(NotificationGroup.sharedBill)[1].on, isFalse);
    expect(s.ofGroup(NotificationGroup.request).single.mutable, isFalse);
    // A group this build doesn't know is left out, not a crash.
    expect(s.types.any((t) => t.type == 'some_future_type'), isFalse);
    // Missing keys (an older BE) fall back to on.
    final bare = NotificationSettings.fromJson({'muted_types': <String>[]});
    expect(bare.types, isEmpty);
    expect(bare.autoSyncEvents && bare.autoSyncDebts, isTrue);
  });

  test(
    'a flip is ONE PUT of the whole muted list; same value sends none',
    () async {
      final repo = _Repo(fail: false);
      final cubit = NotificationSettingsCubit(repository: repo);
      await cubit.load();

      await cubit.setOn('recurring_due', false);
      expect(repo.puts.single, {'split_changed', 'recurring_due'});
      expect(
        cubit.state.settings!.ofGroup(NotificationGroup.recurring).single.on,
        isFalse,
      );

      await cubit.setOn('split_changed', true);
      expect(repo.puts.last, {'recurring_due'});

      await cubit.setOn('split_changed', true);
      expect(repo.puts, hasLength(2), reason: 'already on: no call');
      await cubit.close();
    },
  );

  test('a failed save puts the switch back and keeps the error', () async {
    final repo = _Repo(fail: true);
    final cubit = NotificationSettingsCubit(repository: repo);
    await cubit.load();

    await cubit.setOn('recurring_due', false);
    expect(repo.puts, hasLength(1));
    expect(cubit.state.status, SettingsStatus.error);
    expect(cubit.state.error?.code, 'INTERNAL');
    expect(
      cubit.state.settings!.ofGroup(NotificationGroup.recurring).single.on,
      isTrue,
    );
    await cubit.close();
  });
}
