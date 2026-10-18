import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/data/accounts_repository.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/contacts/data/contacts_repository.dart';
import 'package:chubi_pocket/features/notifications/data/notifications_repository.dart';
import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/notification_actions.dart';
import 'package:chubi_pocket/features/notifications/presentation/pages/notifications_inbox_page.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/recurring/data/recurring_repository.dart';
import 'package:chubi_pocket/features/recurring/domain/recurring_item.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../shared/fake_sync.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

/// One notification the way `GET /notifications` sends it.
Map<String, dynamic> _row(
  String id,
  String type, {
  Map<String, dynamic> payload = const {},
  String state = 'unread',
  bool awaits = false,
  bool system = false,
  String? deepLink,
}) => {
  'id': id,
  'type': type,
  'actor': system
      ? null
      : {'user_id': 'u-bee', 'display_name': 'Bee', 'icon_code': null},
  'payload': payload,
  'deep_link': deepLink,
  'state': state,
  'awaits_answer': awaits,
  'read_at': null,
  'actioned_at': null,
  'dismissed_at': state == 'dismissed' ? '2026-10-16T10:00:00Z' : null,
  'created_at': '2026-10-16T09:30:00Z',
};

/// Every type the inbox renders, shaped like prod rows.
List<Map<String, dynamic>> _allTypes() => [
  _row(
    'n1',
    'split_created',
    awaits: true,
    payload: {'split_id': 's1', 'amount': 450, 'currency': 'THB'},
  ),
  _row(
    'n2',
    'split_changed',
    awaits: true,
    payload: {
      'split_id': 's1',
      'change': 'amount',
      'splitter_display_name': 'Bee',
      'old_amount': 120,
      'new_amount': 150,
      'description': 'Taxi',
      'recipient_debt_id': 'd1',
    },
  ),
  _row(
    'n3',
    'project_tx_recorded_for_you',
    awaits: true,
    payload: {
      'project_id': 'p1',
      'project_transaction_id': 'pt1',
      'amount': 2400,
    },
    deepLink: '/projects/p1',
  ),
  _row(
    'n4',
    'project_tx_changed',
    awaits: true,
    payload: {
      'project_id': 'p1',
      'project_transaction_id': 'pt1',
      'personal_transaction_id': 't1',
      'suggested': {'amount': 2600},
    },
    deepLink: '/projects/p1',
  ),
  _row(
    'n5',
    'project_invite',
    awaits: true,
    payload: {
      'project_member_id': 'm1',
      'project_id': 'p9',
      'project_name': 'Japan trip',
      'inviter_user_id': 'u-bee',
      'inviter_display_name': 'Bee',
      'role': 'contributor',
    },
    deepLink: '/projects/link-requests/n5',
  ),
  _row(
    'n6',
    'project_added',
    state: 'read',
    payload: {'project_id': 'p2', 'project_name': 'Dinner party'},
    deepLink: '/projects/p2',
  ),
  _row(
    'n7',
    'contact_link_request',
    awaits: true,
    payload: {
      'contact_id': 'c1',
      'sender_user_id': 'u-bee',
      'sender_display_name': 'Bee',
    },
  ),
  _row(
    'n8',
    'account_invite',
    awaits: true,
    payload: {'account_id': 'a1', 'account_name': 'Rent'},
  ),
  _row(
    'n9',
    'recurring_due',
    system: true,
    payload: {'count': 3},
    deepLink: '/pending',
  ),
  _row(
    'n10',
    'recurring_ending',
    awaits: true,
    system: true,
    payload: {
      'recurring_id': 'r1',
      'name': 'iPhone',
      'left': 2,
      'start_date': '2026-01-01',
      'end': {'kind': 'count', 'count': 10},
    },
    deepLink: '/recurring/r1',
  ),
];

class _ListCall {
  _ListCall(this.read, this.dismissed, this.awaitsAnswer);
  final String? read;
  final String? dismissed;
  final String? awaitsAnswer;
}

/// `list` runs the real shape parsing and records each call's filter;
/// writes record what was hit.
class _Repo extends Fake implements NotificationsRepository {
  List<Map<String, dynamic>> rows = _allTypes();
  List<Map<String, dynamic>> hidden = [];
  bool down = false;
  final lists = <_ListCall>[];
  final writes = <String>[];

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
    if (down) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no net');
    }
    final data = dismissed == 'true' ? hidden : rows;
    return NotificationsPage(
      notifications: data.map(AppNotification.fromJson).toList(),
      unreadCount: 5,
      page: 1,
      perPage: 20,
      total: data.length,
      totalPages: 1,
      summary: _summary(),
    );
  }

  /// The card's numbers as the BE computes them over the rows it holds:
  /// all = not hidden; needs_answer stays 3, unread 5 until a write moves it.
  InboxSummary _summary() => InboxSummary.fromJson({
    'all': rows.length,
    'needs_answer': 3,
    'unread': unread,
    'dismissed': hidden.length,
  });

  int unread = 5;

  NotificationActionResult _result(String id, {String state = 'read'}) =>
      NotificationActionResult(
        notification: AppNotification.fromJson({
          ...[...rows, ...hidden].firstWhere(
            (r) => r['id'] == id,
            orElse: () => _row(id, 'project_added'),
          ),
          'state': state,
        }),
        badges: Badges(unreadNotifications: unread, pendingDrafts: 0),
        summary: _summary(),
      );

  @override
  Future<NotificationActionResult> markDismissed(String id) async {
    writes.add('dismiss:$id');
    // The BE now answers the row as hidden.
    final i = rows.indexWhere((r) => r['id'] == id);
    if (i >= 0) hidden.add(rows.removeAt(i));
    return _result(id, state: 'dismissed');
  }

  @override
  Future<NotificationActionResult> restore(String id) async {
    writes.add('restore:$id');
    final i = hidden.indexWhere((r) => r['id'] == id);
    if (i >= 0) rows.add(hidden.removeAt(i));
    return _result(id, state: 'unread');
  }

  @override
  Future<NotificationActionResult> markActioned(String id) async {
    writes.add('actioned:$id');
    return _result(id);
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

class _Projects extends Fake implements ProjectsRepository {
  final calls = <String>[];

  @override
  Future<InboxSummary> acceptInvite(String notificationId) async {
    calls.add('accept:$notificationId');
    return const InboxSummary(all: 1, needsAnswer: 0, unread: 0);
  }

  @override
  Future<InboxSummary> rejectInvite(String notificationId) async {
    calls.add('reject:$notificationId');
    return const InboxSummary(all: 1, needsAnswer: 0, unread: 0);
  }
}

/// Invite / link-request answers carry the inbox `summary`.
class _Accounts extends Fake implements AccountsRepository {
  final calls = <String>[];

  @override
  Future<AcceptedInvite> acceptInvite(String notificationId) async {
    calls.add('accept:$notificationId');
    return AcceptedInvite(
      account: Account.fromJson({
        'id': 'a1',
        'name': 'Rent',
        'type': 'bank',
        'group': 'asset',
        'balance': 0.0,
        'currency': 'THB',
        'icon_code': {'icon': 'bank', 'color': 'blue'},
        'status': 'active',
        'sort_order': 1,
        'my_role': 'member',
        'can_edit': true,
        'is_shared': true,
        'track_balance': true,
      }),
      answer: NotificationActionResult(
        notification: AppNotification.fromJson({
          ..._allTypes()[7],
          'state': 'actioned',
          'awaits_answer': false,
        }),
        badges: const Badges(unreadNotifications: 4, pendingDrafts: 0),
        summary: const InboxSummary(all: 10, needsAnswer: 2, unread: 4),
      ),
    );
  }
}

class _Contacts extends Fake implements ContactsRepository {
  final calls = <String>[];

  @override
  Future<LinkRequestResult> rejectLinkRequest(String notificationId) async {
    calls.add('reject:$notificationId');
    return LinkRequestResult.fromJson({
      'contact': null,
      'notification': {
        ..._allTypes()[6],
        'state': 'dismissed',
        'awaits_answer': false,
        'dismissed_at': '2026-10-16T10:00:00Z',
      },
      'badges': {'unread_notifications': 3, 'pending_drafts': 0},
      'summary': {'all': 9, 'needs_answer': 2, 'unread': 3, 'dismissed': 1},
    });
  }
}

class _Recurring extends Fake implements RecurringRepository {
  final calls = <String>[];

  @override
  Future<RecurringDetail> extend(String id, {Map<String, dynamic>? end}) async {
    calls.add('extend:$id:$end');
    throw const ApiException(code: 'STOP', message: 'stop here');
  }
}

void main() {
  extendedEndTests();
  late _Repo repo;
  late _Projects projects;
  late _Recurring recurring;
  late _Accounts accounts;
  late _Contacts contacts;

  setUp(() {
    repo = _Repo();
    projects = _Projects();
    recurring = _Recurring();
    accounts = _Accounts();
    contacts = _Contacts();
  });

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(800, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    await t.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NotificationsRepository>.value(value: repo),
          RepositoryProvider<ProjectsRepository>.value(value: projects),
          RepositoryProvider<RecurringRepository>.value(value: recurring),
          RepositoryProvider<AccountsRepository>.value(value: accounts),
          RepositoryProvider<ContactsRepository>.value(value: contacts),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>(
              create: (_) => AccountsCubit(repository: accounts, coordinator: testCoordinator()),
            ),
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(child: child!),
            home: const NotificationsInboxPage(),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump();
  }

  Finder tile(String label) => find.byKey(ValueKey('summaryTile:$label'));

  Finder tileValue(String label, String value) =>
      find.descendant(of: tile(label), matching: find.text(value));

  testWidgets('opens with ONE call and shows the card numbers', (t) async {
    await pump(t);
    expect(repo.lists, hasLength(1));
    expect(repo.lists.single.read, isNull);
    expect(repo.lists.single.dismissed, isNull);
    // needs_answer 3, unread 5, hidden 0 — straight from `summary`.
    expect(tileValue('Needs answer', '3'), findsOneWidget);
    expect(tileValue('Unread', '5'), findsOneWidget);
    expect(tileValue('Hidden', '0'), findsOneWidget);
    expect(tileValue('All', '10'), findsOneWidget);
  });

  testWidgets('every notification type renders as one tile', (t) async {
    await pump(t);
    expect(find.byType(NotificationTileView), findsNWidgets(10));
    expect(find.text('Bee invited you to Japan trip'), findsOneWidget);
    expect(find.textContaining('iPhone has 2 items left'), findsOneWidget);
    expect(find.textContaining('3 recurring items are due'), findsOneWidget);
    expect(find.text('Bee added you to Dinner party'), findsOneWidget);
    // Answer buttons: invites + requests, one-tap actions, ending, due.
    expect(find.text('Extend'), findsOneWidget);
    expect(find.text('Let it end'), findsOneWidget);
    expect(find.text('Open pending ›'), findsOneWidget);
    expect(find.text('Add to my payables'), findsOneWidget);
    // The settings row is gone from the list.
    expect(find.text('Notification settings'), findsNothing);
  });

  testWidgets('each filter tile is one call; tapping again clears', (t) async {
    await pump(t);

    await t.tap(tile('Unread'));
    await t.pump();
    await t.pump();
    expect(repo.lists, hasLength(2));
    expect(repo.lists.last.read, 'false');

    await t.tap(tile('Unread')); // clear → all
    await t.pump();
    await t.pump();
    expect(repo.lists, hasLength(3));
    expect(repo.lists.last.read, isNull);

    await t.tap(tile('Needs answer'));
    await t.pump();
    await t.pump();
    expect(repo.lists, hasLength(4));
    expect(repo.lists.last.awaitsAnswer, 'true');

    await t.tap(tile('Hidden'));
    await t.pump();
    await t.pump();
    expect(repo.lists, hasLength(5));
    expect(repo.lists.last.dismissed, 'true');
  });

  testWidgets('swipe hides the row with an undo that restores it', (t) async {
    repo.rows = [
      _row(
        'n6',
        'project_added',
        state: 'read',
        payload: {'project_id': 'p2', 'project_name': 'Dinner party'},
      ),
    ];
    await pump(t);
    expect(find.text('Bee added you to Dinner party'), findsOneWidget);

    await t.drag(find.byType(Dismissible), const Offset(-700, 0));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    await t.pump();

    expect(repo.writes, ['dismiss:n6']);
    // Hide = one POST; the card follows the answer, no re-fetch.
    expect(repo.lists, hasLength(1));
    expect(find.text('Bee added you to Dinner party'), findsNothing);
    expect(tileValue('All', '0'), findsOneWidget);
    expect(tileValue('Hidden', '1'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Undo'));
    await t.pump();
    await t.pump();
    expect(repo.writes, ['dismiss:n6', 'restore:n6']);
    // Undo puts the row back from the answer; still no re-fetch.
    expect(repo.lists, hasLength(1));
    expect(find.text('Bee added you to Dinner party'), findsOneWidget);
    expect(tileValue('All', '1'), findsOneWidget);
    expect(tileValue('Hidden', '0'), findsOneWidget);
  });

  testWidgets('mark all read flips the rows and takes the numbers from the '
      'answer', (t) async {
    await pump(t);
    expect(tileValue('Unread', '5'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Mark all as read'));
    await t.pump();
    await t.pump();
    expect(repo.writes, ['read-all']);
    expect(repo.lists, hasLength(1));
    expect(tileValue('Unread', '0'), findsOneWidget);
    expect(find.byType(NotificationTileView), findsNWidgets(10));
  });

  testWidgets('the Hidden tile lists hidden rows with Restore', (t) async {
    repo.hidden = [
      _row(
        'h1',
        'project_added',
        state: 'dismissed',
        payload: {'project_id': 'p2', 'project_name': 'Dinner party'},
      ),
    ];
    await pump(t);
    await t.tap(tile('Hidden'));
    await t.pump();
    await t.pump();
    expect(find.text('Bee added you to Dinner party'), findsOneWidget);
    expect(find.byType(Dismissible), findsNothing);

    await t.tap(find.text('Restore'));
    await t.pump();
    await t.pump();
    expect(repo.writes, ['restore:h1']);
  });

  testWidgets(
    'project_invite: Accept / Reject hit the event routes, no re-fetch',
    (t) async {
      repo.rows = [_allTypes()[4]];
      await pump(t);
      await t.tap(find.text('Accept'));
      await t.pump();
      await t.pump();
      expect(projects.calls, ['accept:n5']);
      // The answer carries `inbox_summary`: the list was not asked again.
      expect(repo.lists, hasLength(1));
    },
  );

  testWidgets('project_invite: Reject asks first, then one call, no re-fetch', (
    t,
  ) async {
    repo.rows = [_allTypes()[4]];
    await pump(t);
    await t.tap(find.text('Reject'));
    await t.pump();
    await t.pump();
    // Rejecting asks first.
    expect(find.text('Decline this request?'), findsOneWidget);
    await t.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Reject'),
      ),
    );
    await t.pump();
    await t.pump();
    expect(projects.calls, ['reject:n5']);
    expect(repo.lists, hasLength(1));
  });

  testWidgets('wallet invite: Accept takes the answer, NO re-fetch', (t) async {
    repo.rows = [_allTypes()[7]];
    await pump(t);
    expect(repo.lists, hasLength(1));
    await t.tap(find.text('Accept'));
    await t.pump();
    await t.pump();
    expect(accounts.calls, ['accept:n8']);
    // The card follows the answer's summary; the list was not asked again.
    expect(repo.lists, hasLength(1));
    expect(tileValue('Needs answer', '2'), findsOneWidget);
    expect(tileValue('Unread', '4'), findsOneWidget);
  });

  testWidgets('link request: Reject takes the answer, the row leaves, no '
      're-fetch', (t) async {
    repo.rows = [_allTypes()[6]];
    await pump(t);
    await t.tap(find.text('Reject'));
    await t.pump();
    await t.pump();
    await t.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Reject'),
      ),
    );
    await t.pump();
    await t.pump();
    expect(contacts.calls, ['reject:n7']);
    expect(repo.lists, hasLength(1));
    expect(find.byType(NotificationTileView), findsNothing);
    expect(tileValue('All', '9'), findsOneWidget);
    expect(tileValue('Hidden', '1'), findsOneWidget);
  });

  testWidgets('recurring_ending: Extend calls /extend, Let it end = actioned', (
    t,
  ) async {
    repo.rows = [_allTypes()[9]];
    await pump(t);
    await t.tap(find.text('Extend'));
    await t.pump();
    await t.pump();
    expect(recurring.calls, ['extend:r1:{kind: count, count: 20}']);

    await t.tap(find.text('Let it end'));
    await t.pump();
    await t.pump();
    expect(repo.writes, ['actioned:n10']);
  });

  testWidgets('a failing load keeps the rows on screen', (t) async {
    await pump(t);
    expect(find.byType(NotificationTileView), findsNWidgets(10));

    repo.down = true;
    await t.tap(tile('Unread'));
    await t.pump();
    await t.pump();
    expect(repo.lists, hasLength(2));
    expect(find.byType(NotificationTileView), findsNWidgets(10));
    expect(find.text('no net'), findsOneWidget);
  });

  testWidgets('a failing first load shows the page error with a retry', (
    t,
  ) async {
    repo.down = true;
    await pump(t);
    expect(find.byType(NotificationTileView), findsNothing);
    repo.down = false;
    await t.tap(find.text('Retry'));
    await t.pump();
    await t.pump();
    expect(find.byType(NotificationTileView), findsNWidgets(10));
  });
}

void extendedEndTests() {
  test('extendedEnd: the same length again, from the payload only', () {
    expect(
      extendedEnd({
        'end': {'kind': 'count', 'count': 6},
      }),
      {'kind': 'count', 'count': 12},
    );
    // 2026-01-01 → 2026-07-01 is 181 days: the new end adds the same span.
    expect(
      extendedEnd({
        'start_date': '2026-01-01',
        'end': {'kind': 'date', 'date': '2026-07-01'},
      }),
      {'kind': 'date', 'date': '2026-12-29'},
    );
    // No start in the payload: +1 year.
    expect(
      extendedEnd({
        'end': {'kind': 'date', 'date': '2026-07-01'},
      }),
      {'kind': 'date', 'date': '2027-07-01'},
    );
    expect(
      extendedEnd({
        'end': {'kind': 'none'},
      }),
      isNull,
    );
    expect(extendedEnd({'name': 'x'}), isNull);
  });
}
