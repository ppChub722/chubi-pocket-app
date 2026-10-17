import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/data/notifications_repository.dart';
import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
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
    payload: {'recurring_id': 'r1', 'name': 'iPhone', 'left': 2},
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
      summary: InboxSummary.fromJson({
        'needs_answer': 3,
        'unread': 5,
        'dismissed': hidden.length,
      }),
    );
  }

  NotificationActionResult _result(String id) => NotificationActionResult(
    notification: AppNotification.fromJson(_row(id, 'project_added')),
    badges: const Badges(unreadNotifications: 4, pendingDrafts: 0),
  );

  @override
  Future<NotificationActionResult> markDismissed(String id) async {
    writes.add('dismiss:$id');
    // The BE now answers the row as hidden.
    final i = rows.indexWhere((r) => r['id'] == id);
    if (i >= 0) hidden.add(rows.removeAt(i));
    return _result(id);
  }

  @override
  Future<NotificationActionResult> restore(String id) async {
    writes.add('restore:$id');
    final i = hidden.indexWhere((r) => r['id'] == id);
    if (i >= 0) rows.add(hidden.removeAt(i));
    return _result(id);
  }

  @override
  Future<NotificationActionResult> markActioned(String id) async {
    writes.add('actioned:$id');
    return _result(id);
  }

  @override
  Future<Badges> markReadAll() async {
    writes.add('read-all');
    return const Badges(unreadNotifications: 0, pendingDrafts: 0);
  }
}

class _Projects extends Fake implements ProjectsRepository {
  final calls = <String>[];

  @override
  Future<void> acceptInvite(String notificationId) async =>
      calls.add('accept:$notificationId');

  @override
  Future<void> rejectInvite(String notificationId) async =>
      calls.add('reject:$notificationId');
}

class _Recurring extends Fake implements RecurringRepository {
  final calls = <String>[];

  @override
  Future<RecurringDetail> action(String id, RecurringAction action) async {
    calls.add('${action.name}:$id');
    throw const ApiException(code: 'STOP', message: 'stop here');
  }
}

void main() {
  late _Repo repo;
  late _Projects projects;
  late _Recurring recurring;

  setUp(() {
    repo = _Repo();
    projects = _Projects();
    recurring = _Recurring();
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
        ],
        child: MultiBlocProvider(
          providers: [
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
    // Hide = one POST, then the page's one re-fetch.
    expect(repo.lists, hasLength(2));
    expect(find.text('Hidden'), findsWidgets);
    expect(find.text('Undo'), findsOneWidget);

    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Undo'));
    await t.pump();
    await t.pump();
    expect(repo.writes, ['dismiss:n6', 'restore:n6']);
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

  testWidgets('project_invite: Accept / Reject hit the event routes', (
    t,
  ) async {
    repo.rows = [_allTypes()[4]];
    await pump(t);
    await t.tap(find.text('Accept'));
    await t.pump();
    await t.pump();
    expect(projects.calls, ['accept:n5']);
    // The answer is followed by the page's one re-fetch.
    expect(repo.lists, hasLength(2));

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
    expect(projects.calls, ['accept:n5', 'reject:n5']);
  });

  testWidgets('recurring_ending: Extend calls /extend, Let it end = actioned', (
    t,
  ) async {
    repo.rows = [_allTypes()[9]];
    await pump(t);
    await t.tap(find.text('Extend'));
    await t.pump();
    await t.pump();
    expect(recurring.calls, ['extend:r1']);

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
