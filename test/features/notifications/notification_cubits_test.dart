import 'package:chubi_pocket/features/notifications/data/notifications_repository.dart';
import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/notifications_inbox_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/notification_routes.dart';
import 'package:flutter_test/flutter_test.dart';

class _SettingsRepo extends Fake implements NotificationsRepository {
  var settings = NotificationSettings.fromJson({
    'muted_types': ['split_changed', 'recurring_ending'],
    'auto_types': ['project_tx_changed'],
    'default_account': null,
  });
  final puts = <({Set<String>? muted, Set<String>? auto})>[];

  @override
  Future<NotificationSettings> getSettings() async => settings;

  @override
  Future<NotificationSettings> updateSettings({
    Set<String>? mutedTypes,
    Set<String>? autoTypes,
    String? defaultAccountId,
    bool clearDefaultAccount = false,
  }) async {
    puts.add((muted: mutedTypes, auto: autoTypes));
    return settings = NotificationSettings(
      mutedTypes: mutedTypes ?? settings.mutedTypes,
      autoTypes: autoTypes ?? settings.autoTypes,
    );
  }
}

Map<String, dynamic> _row(
  String id,
  String type, {
  String state = 'unread',
  bool awaits = false,
}) => {
  'id': id,
  'type': type,
  'actor': {'user_id': 'u-bee', 'display_name': 'Bee', 'icon_code': null},
  'payload': <String, dynamic>{},
  'deep_link': null,
  'state': state,
  'awaits_answer': awaits,
  'read_at': null,
  'actioned_at': null,
  'dismissed_at': state == 'dismissed' ? '2026-10-16T10:00:00Z' : null,
  'created_at': '2026-10-16T09:30:00Z',
};

class _ListCall {
  _ListCall(this.read, this.dismissed, this.awaitsAnswer);
  final String? read;
  final String? dismissed;
  final String? awaitsAnswer;
}

class _InboxRepo extends Fake implements NotificationsRepository {
  _InboxRepo(this.rows);

  List<Map<String, dynamic>> rows;
  List<Map<String, dynamic>> hidden = [];
  int unread = 5;
  final lists = <_ListCall>[];
  final writes = <String>[];

  InboxSummary _summary() => InboxSummary.fromJson({
    'all': rows.length,
    'needs_answer': 3,
    'unread': unread,
    'dismissed': hidden.length,
  });

  NotificationActionResult _result(String id, String state) =>
      NotificationActionResult(
        notification: AppNotification.fromJson({
          ...[...rows, ...hidden].firstWhere((r) => r['id'] == id),
          'state': state,
        }),
        badges: Badges(unreadNotifications: unread, pendingDrafts: 0),
        summary: _summary(),
      );

  @override
  Future<NotificationsPage> list({
    String? read,
    String? actioned,
    String? dismissed,
    String? awaitsAnswer,
    String? type,
    String? from,
    String? to,
    int page = 1,
    int perPage = 20,
  }) async {
    lists.add(_ListCall(read, dismissed, awaitsAnswer));
    final data = dismissed == 'true' ? hidden : rows;
    return NotificationsPage(
      notifications: data.map(AppNotification.fromJson).toList(),
      unreadCount: unread,
      page: 1,
      perPage: 20,
      total: data.length,
      totalPages: 1,
      summary: _summary(),
    );
  }

  @override
  Future<NotificationActionResult> markDismissed(String id) async {
    writes.add('dismiss:$id');
    final i = rows.indexWhere((r) => r['id'] == id);
    if (i >= 0) hidden.add(rows.removeAt(i));
    return _result(id, 'dismissed');
  }

  @override
  Future<NotificationActionResult> restore(String id) async {
    writes.add('restore:$id');
    final i = hidden.indexWhere((r) => r['id'] == id);
    if (i >= 0) rows.add(hidden.removeAt(i));
    return _result(id, 'unread');
  }

  @override
  Future<NotificationActionResult> markActioned(String id) async {
    writes.add('actioned:$id');
    return _result(id, 'actioned');
  }

  @override
  Future<InboxCounts> markReadAll() async {
    writes.add('read-all');
    unread = 0;
    return InboxCounts(
      badges: const Badges(unreadNotifications: 0, pendingDrafts: 0),
      summary: _summary(),
    );
  }
}

void main() {
  test('settings: a mode change is ONE PUT with only the changed list', () async {
    final repo = _SettingsRepo();
    final cubit = NotificationSettingsCubit(repository: repo);
    await cubit.load();
    final steps = [
      (
        name: 'notify -> auto: only auto_types',
        type: NotificationType.splitCreated,
        mode: NotifyMode.auto,
        muted: null,
        auto: {'project_tx_changed', 'split_created'},
      ),
      (
        name: 'off -> notify: only muted_types',
        type: NotificationType.recurringEnding,
        mode: NotifyMode.notify,
        muted: {'split_changed'},
        auto: null,
      ),
      (
        name: 'notify -> off: muted gains the type',
        type: NotificationType.recurringDue,
        mode: NotifyMode.off,
        muted: {'split_changed', 'recurring_due'},
        auto: null,
      ),
      (
        name: 'auto -> off: both lists change',
        type: NotificationType.projectTxChanged,
        mode: NotifyMode.off,
        muted: {'split_changed', 'recurring_due', 'project_tx_changed'},
        auto: {'split_created'},
      ),
    ];
    for (final (i, c) in steps.indexed) {
      await cubit.setMode(c.type, c.mode);
      expect(repo.puts, hasLength(i + 1), reason: c.name);
      expect(repo.puts.last.muted, c.muted, reason: c.name);
      expect(repo.puts.last.auto, c.auto, reason: c.name);
    }
    await cubit.setMode(NotificationType.recurringDue, NotifyMode.off);
    expect(repo.puts, hasLength(steps.length), reason: 'same state sends none');
    await cubit.close();
  });

  test('inbox: each filter is one call with its own query', () async {
    for (final c in [
      (f: InboxFilter.all, read: null, dismissed: null, awaits: null),
      (f: InboxFilter.unread, read: 'false', dismissed: null, awaits: null),
      (f: InboxFilter.needsAnswer, read: null, dismissed: null, awaits: 'true'),
      (f: InboxFilter.hidden, read: null, dismissed: 'true', awaits: null),
    ]) {
      final repo = _InboxRepo([_row('n1', 'project_added')]);
      final cubit = NotificationsInboxCubit(repository: repo);
      await cubit.load(filter: c.f);
      expect(repo.lists, hasLength(1), reason: c.f.name);
      expect(repo.lists.single.read, c.read, reason: c.f.name);
      expect(repo.lists.single.dismissed, c.dismissed, reason: c.f.name);
      expect(repo.lists.single.awaitsAnswer, c.awaits, reason: c.f.name);
      await cubit.close();
    }
  });

  test('inbox: picking the filter again is no call', () async {
    final repo = _InboxRepo([_row('n1', 'project_added')]);
    final cubit = NotificationsInboxCubit(repository: repo);
    await cubit.load();
    for (final c in [
      (f: InboxFilter.unread, calls: 2),
      (f: InboxFilter.unread, calls: 2),
      (f: InboxFilter.all, calls: 3),
      (f: InboxFilter.needsAnswer, calls: 4),
      (f: InboxFilter.hidden, calls: 5),
      (f: InboxFilter.hidden, calls: 5),
    ]) {
      await cubit.pick(c.f);
      expect(repo.lists, hasLength(c.calls), reason: c.f.name);
    }
    expect(repo.lists.last.dismissed, 'true');
    await cubit.close();
  });

  test('accept / reject: which call a notification type routes to', () {
    for (final c in [
      (t: NotificationType.accountInvite, accept: AcceptRoute.walletInvite, reject: RejectRoute.walletInvite),
      (t: NotificationType.splitCreated, accept: AcceptRoute.split, reject: RejectRoute.dismiss),
      (t: NotificationType.splitChanged, accept: AcceptRoute.splitChange, reject: RejectRoute.dismiss),
      (t: NotificationType.projectTxRecordedForYou, accept: AcceptRoute.copyToBook, reject: RejectRoute.dismiss),
      (t: NotificationType.projectTxChanged, accept: AcceptRoute.updateCopy, reject: RejectRoute.dismiss),
      (t: NotificationType.projectInvite, accept: AcceptRoute.projectInvite, reject: RejectRoute.projectInvite),
      (t: NotificationType.recurringEnding, accept: AcceptRoute.extendRecurring, reject: RejectRoute.markActioned),
      (t: NotificationType.recurringDue, accept: AcceptRoute.openDue, reject: RejectRoute.dismiss),
      (t: NotificationType.contactLinkRequest, accept: AcceptRoute.linkRequest, reject: RejectRoute.linkRequest),
      (t: NotificationType.projectAdded, accept: AcceptRoute.linkRequest, reject: RejectRoute.dismiss),
    ]) {
      expect(acceptRouteOf(c.t), c.accept, reason: c.t.name);
      expect(rejectRouteOf(c.t), c.reject, reason: c.t.name);
    }
  });

  test('inbox: hide = one POST, undo restores it, never a re-fetch', () async {
    final repo = _InboxRepo([_row('n6', 'project_added', state: 'read')]);
    final cubit = NotificationsInboxCubit(repository: repo);
    await cubit.load();
    expect(cubit.state.summary.all, 1);

    expect(await cubit.hide('n6'), isTrue);
    expect(repo.writes, ['dismiss:n6']);
    expect(cubit.state.notifications, isEmpty);
    expect(cubit.state.summary.all, 0);
    expect(cubit.state.summary.dismissed, 1);

    expect(await cubit.restore('n6'), isTrue);
    expect(repo.writes, ['dismiss:n6', 'restore:n6']);
    expect(cubit.state.notifications.map((n) => n.id), ['n6']);
    expect(cubit.state.summary.all, 1);
    expect(cubit.state.summary.dismissed, 0);
    expect(repo.lists, hasLength(1));

    repo.hidden = [_row('h1', 'project_added', state: 'dismissed')];
    await cubit.load(filter: InboxFilter.hidden);
    expect(cubit.state.notifications.map((n) => n.id), ['h1']);
    await cubit.restore('h1');
    expect(repo.writes.last, 'restore:h1');
    expect(cubit.state.notifications, isEmpty);
    await cubit.close();
  });

  test('inbox: mark all read flips the rows, numbers from the answer', () async {
    final repo = _InboxRepo([
      _row('n1', 'split_created', awaits: true),
      _row('n2', 'project_added', state: 'read'),
    ]);
    final badge = <int>[];
    final cubit = NotificationsInboxCubit(
      repository: repo,
      onUnreadChanged: badge.add,
    );
    await cubit.load();
    expect(cubit.state.summary.unread, 5);

    await cubit.markReadAll();
    expect(repo.writes, ['read-all']);
    expect(repo.lists, hasLength(1));
    expect(cubit.state.notifications.every((n) => !n.isUnread), isTrue);
    expect(cubit.state.notifications, hasLength(2));
    expect(cubit.state.summary.unread, 0);
    expect(cubit.state.unreadCount, 0);
    expect(badge.last, 0);
    await cubit.close();
  });

  test('inbox: answers take the card numbers from the reply, no re-fetch', () async {
    final repo = _InboxRepo([
      _row('n5', 'project_invite', awaits: true),
      _row('n7', 'contact_link_request', awaits: true),
      _row('n8', 'account_invite', awaits: true),
      _row('n10', 'recurring_ending', awaits: true),
    ]);
    final cubit = NotificationsInboxCubit(repository: repo);
    await cubit.load();

    cubit.applyInboxSummary(
      'n5',
      const InboxSummary(all: 4, needsAnswer: 3, unread: 4),
    );
    expect(
      cubit.state.notifications.firstWhere((n) => n.id == 'n5').isActioned,
      isTrue,
    );
    expect(cubit.state.summary.needsAnswer, 3);
    expect(cubit.state.unreadCount, 4);

    cubit.applyAnswer(
      NotificationActionResult(
        notification: AppNotification.fromJson({
          ..._row('n8', 'account_invite'),
          'state': 'actioned',
        }),
        badges: const Badges(unreadNotifications: 3, pendingDrafts: 0),
        summary: const InboxSummary(all: 4, needsAnswer: 2, unread: 3),
      ),
    );
    expect(
      cubit.state.notifications.firstWhere((n) => n.id == 'n8').isActioned,
      isTrue,
    );
    expect(cubit.state.summary.needsAnswer, 2);
    expect(cubit.state.unreadCount, 3);

    cubit.applyAnswer(
      NotificationActionResult(
        notification: AppNotification.fromJson({
          ..._row('n7', 'contact_link_request'),
          'state': 'dismissed',
        }),
        badges: const Badges(unreadNotifications: 2, pendingDrafts: 0),
        summary: const InboxSummary(
          all: 3,
          needsAnswer: 1,
          unread: 2,
          dismissed: 1,
        ),
      ),
    );
    expect(cubit.state.notifications.map((n) => n.id), [
      'n5',
      'n8',
      'n10',
    ]);
    expect(cubit.state.summary.dismissed, 1);

    await cubit.markActioned('n10');
    expect(repo.writes, ['actioned:n10']);
    expect(
      cubit.state.notifications.firstWhere((n) => n.id == 'n10').isActioned,
      isTrue,
    );
    expect(repo.lists, hasLength(1));
    await cubit.close();
  });
}
