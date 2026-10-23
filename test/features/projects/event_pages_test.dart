import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/projects_cubit.dart';
import 'package:chubi_pocket/features/projects/presentation/project_board_controller.dart';
import 'package:chubi_pocket/features/projects/presentation/pages/project_detail_page.dart';
import 'package:chubi_pocket/features/projects/presentation/pages/projects_page.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'event_fixtures.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

/// Runs the REAL model parsing on spec-shaped bodies, or fails like the
/// network does. Counts the calls (thin FE: one per open / button).
class _Repo extends Fake implements ProjectsRepository {
  bool networkDown = false;
  Map<String, dynamic>? detailBody;

  /// Rows per page and the page count the fake server reports.
  int rowsPerPage = 2;
  int totalPages = 1;
  final calls = <String>[];
  final statuses = <String?>[];
  final payers = <String?>[];

  void _net() {
    if (networkDown) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no connection');
    }
  }

  @override
  Future<ProjectPage> list({
    String? status,
    String? q,
    List<String> tagIds = const [],
    ProjectSort? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add('list q=${q ?? ''} page=$page');
    statuses.add(status);
    _net();
    final summary = ProjectListSummary.fromJson(listSummaryJson());
    if (rowsPerPage > 2) {
      return ProjectPage(
        projects: [
          for (var i = 0; i < rowsPerPage; i++)
            Project.fromJson(
              eventJson(id: 'p$page-$i', name: 'Event $page-$i'),
            ),
        ],
        page: page,
        totalPages: totalPages,
        summary: summary,
      );
    }
    return ProjectPage(
      projects: [
        // I'm owed 250.
        Project.fromJson(eventJson()),
        // I owe 100.
        Project.fromJson(
          eventJson(id: 'e2', name: 'Office party', myNet: -100),
        ),
        // Even.
        Project.fromJson(eventJson(id: 'e3', name: 'Picnic', myNet: 0)),
      ],
      page: page,
      totalPages: totalPages,
      summary: summary,
    );
  }

  @override
  Future<ProjectDetail> detail(
    String id, {
    int perPage = 50,
    bool deletePreview = false,
  }) async {
    calls.add(deletePreview ? 'preview $id' : 'detail $id');
    _net();
    return ProjectDetail.fromJson({
      ...(detailBody ?? detailJson()),
      'delete_preview': deletePreview
          ? {'bills': 3, 'members': 2, 'linked_tx_count': 2}
          : null,
    });
  }

  @override
  Future<List<ProjectTransaction>> listTransactions(
    String projectId, {
    int page = 1,
    int perPage = 20,
    String? type,
    bool mine = false,
    String? q,
    String? tagId,
    String? sort,
    String? payerMemberId,
  }) async {
    calls.add('bills tag=$tagId mine=$mine');
    payers.add(payerMemberId);
    _net();
    return ProjectTransaction.flatten(
      boardRowJson(id: 'b9', description: 'Tagged bill'),
    );
  }

  @override
  Future<EventSettle> settle(String projectId) async {
    calls.add('settle $projectId');
    _net();
    final line = {
      'from': memberRef('m-lee', 'Lee'),
      'to': memberRef('m-me', 'Pond', me: true),
      'amount': 250,
    };
    return EventSettle.fromJson({
      'pairs': [line],
      'simplified': [line],
    });
  }

  @override
  Future<EventPatch> archive(String id) async {
    calls.add('archive $id');
    return EventPatch.fromJson(patchJson());
  }

  @override
  Future<Map<String, double>> delete(
    String id, {
    bool deleteLinkedTxs = false,
  }) async {
    calls.add('delete $id txs=$deleteLinkedTxs');
    return const {'a1': 900};
  }

  @override
  Future<EventPatch> toggleMark(
    String projectId,
    String ptId,
    bool marked,
  ) async {
    calls.add('mark $ptId $marked');
    return EventPatch.fromJson(
      patchJson(
        row: boardRowJson(
          id: ptId,
          marks: ['m-me'],
          payer: memberRef('m-lee', 'Lee'),
        ),
      ),
    );
  }
}

final _theme = ThemeData(
  extensions: [
    ThemeRegistry.byId(
      ThemeRegistry.defaultThemeId,
    ).colorsFor(Brightness.light),
  ],
);

void main() {
  late _Repo repo;
  late ProjectsCubit projects;
  late _Accounts accounts;

  setUp(() {
    repo = _Repo();
    projects = ProjectsCubit(repository: repo);
    accounts = _Accounts();
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => accounts.patchBalances(any())).thenReturn(null);
    ToolbarToggleState.resetAll();
  });

  tearDown(() => projects.close());

  /// [home], or a [router] when the page leaves itself (delete).
  Future<void> pump(WidgetTester t, Widget home, {GoRouter? router}) async {
    // A tall phone: the hero and the sections all fit.
    t.view.physicalSize = const Size(420, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final tags = _Tags();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => tags.state).thenReturn(const TagsState());
    when(() => tags.byId(any())).thenReturn(null);
    await t.pumpWidget(
      RepositoryProvider<ProjectsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<ProjectsCubit>.value(value: projects),
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<TagsCubit>.value(value: tags),
          ],
          child: router == null
              ? MaterialApp(
                  theme: _theme,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: const Locale('en'),
                  builder: (context, child) => AppUiConfig(child: child!),
                  home: home,
                )
              : MaterialApp.router(
                  theme: _theme,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: const Locale('en'),
                  builder: (context, child) => AppUiConfig(child: child!),
                  routerConfig: router,
                ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  /// The edit form of event e1 (the route's `/edit`).
  Future<void> pumpEdit(WidgetTester t) async {
    await pump(t, const ProjectDetailPage(id: 'e1', startEditing: true));
    await t.pumpAndSettle();
  }

  group('events list', () {
    testWidgets('one call; the hero and the rows show the BE numbers', (
      t,
    ) async {
      await pump(t, const ProjectsPage());
      expect(repo.calls, ['list q= page=1']);
      expect(repo.statuses, ['current']);
      // Net owed = gets back − to pay; then the facts.
      expect(find.text('Net owed | 3 events'), findsOneWidget);
      expect(find.text('+฿8,150'), findsOneWidget);
      expect(find.text('Gets back | 2 events'), findsOneWidget);
      expect(find.text('To pay | 1 events'), findsOneWidget);
      expect(find.text('My share | 2 active'), findsOneWidget);
      expect(find.text('฿14,289'), findsOneWidget);
      expect(find.byType(HeroFilterChips), findsOneWidget);
      // All three are active: one section.
      expect(find.byType(SectionHeader), findsOneWidget);
      expect(find.byType(EventListRow), findsNWidgets(3));
      // Right side: gets back (green) / to pay (red) / settled = my share.
      expect(find.text('+฿250'), findsOneWidget);
      expect(find.text('Gets back'), findsOneWidget);
      expect(find.text('−฿100'), findsOneWidget);
      expect(find.text('To pay'), findsOneWidget);
      expect(find.text('Settled up'), findsOneWidget);
      // Each has a plan: the budget bar.
      expect(find.byType(ProgressRow), findsNWidgets(3));
    });

    testWidgets('the hero chips are the status filter', (t) async {
      await pump(t, const ProjectsPage());
      await t.tap(find.text('Not settled'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      // The derived filter is the server's: sent as `status`, the rows it
      // answers are shown as they are (no client-side narrowing).
      expect(repo.statuses.last, 'unsettled');
      expect(find.byType(EventListRow), findsNWidgets(3));
      expect(repo.calls.length, 2);
      await t.tap(find.text('All'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.statuses.last, 'current');
    });

    testWidgets('the ended chip sends status=ended', (t) async {
      await pump(t, const ProjectsPage());
      await t.tap(find.text('Ended'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.statuses.last, 'ended');
      expect(repo.calls.length, 2);
    });

    testWidgets('search runs on the server (debounced, one call)', (t) async {
      ToolbarToggleState.of('events').value = true;
      await pump(t, const ProjectsPage());
      await t.enterText(find.byType(TextField).first, 'trip');
      await t.pump(const Duration(milliseconds: 400));
      await t.pump();
      expect(repo.calls.last, 'list q=trip page=1');
      expect(repo.calls.length, 2);
    });

    testWidgets('a page that fits the screen still pulls the next one', (
      t,
    ) async {
      repo.totalPages = 2;
      await pump(t, const ProjectsPage());
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls, ['list q= page=1', 'list q= page=2']);
    });

    testWidgets('network down → error + retry', (t) async {
      repo.networkDown = true;
      await pump(t, const ProjectsPage());
      expect(find.byType(ErrorView), findsOneWidget);
      repo.networkDown = false;
      await t.tap(find.text('Retry'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(EventListRow), findsNWidgets(3));
    });

    testWidgets('a failed refresh keeps the rows and says so', (t) async {
      await pump(t, const ProjectsPage());
      repo.networkDown = true;
      await projects.load();
      await t.pump();
      expect(find.byType(EventListRow), findsNWidgets(3));
      expect(find.byType(ErrorView), findsNothing);
      expect(
        find.text('Couldn\'t refresh | showing the last data'),
        findsOneWidget,
      );
    });
  });

  group('event page', () {
    testWidgets('one call; hero, budget bar, member strip, tag chips', (
      t,
    ) async {
      await pump(t, const ProjectDetailPage(id: 'e1'));
      expect(repo.calls, ['detail e1']);
      expect(find.byType(ErrorView), findsNothing);
      // Hero: total spent, the budget bar (a plan is set), the tiles.
      expect(find.text('Total spent'), findsOneWidget);
      // The budget bar: what's spent on the fill, the budget at its end.
      expect(find.byKey(const ValueKey('progressFillLabel')), findsOneWidget);
      expect(find.text('฿10,000'), findsOneWidget);
      expect(find.text('My share'), findsOneWidget);
      expect(find.text('Gets back'), findsOneWidget);
      // No income → no income line.
      expect(find.text('Total income'), findsNothing);
      expect(find.text('My tags:'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
      // Search + "only mine" on the first date header; the toolbar is shut.
      expect(find.byKey(const ValueKey('billsSearch')), findsOneWidget);
      expect(find.text('Only mine'), findsOneWidget);
      expect(find.byKey(const ValueKey('billsTagFilter')), findsNothing);
      expect(find.text('Food'), findsWidgets);
      // Tabs: the bills first; the member strip lives in Summary.
      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.byType(EventBillRow), findsNWidgets(2));
      expect(find.byType(PeopleStrip), findsNothing);
    });

    testWidgets('the summary tab: the member strip and who pays whom', (
      t,
    ) async {
      await pump(t, const ProjectDetailPage(id: 'e1'));
      await t.tap(find.text('Summary'));
      await t.pumpAndSettle();
      expect(repo.calls, ['detail e1', 'settle e1']);
      expect(find.byType(PeopleStrip), findsOneWidget);
      expect(find.text('Paid ฿1,000'), findsOneWidget);
      expect(find.text('Owed ฿250'), findsOneWidget);
      expect(find.text('Owes ฿250'), findsOneWidget);
      expect(find.text('Lee → Pond'), findsOneWidget);
      expect(find.text('Pair by pair'), findsOneWidget);
    });

    testWidgets('no planned budget → no bar; income → the income line', (
      t,
    ) async {
      final body = detailJson();
      final event = body['event'] as Map<String, dynamic>;
      event['planned_amount'] = null;
      event['remaining'] = null;
      event['total_income'] = 500;
      repo.detailBody = body;
      await pump(t, const ProjectDetailPage(id: 'e1'));
      expect(find.textContaining('budget'), findsNothing);
      expect(find.text('Total income'), findsOneWidget);
    });

    testWidgets('the tag filter (search → Tags) filters with one call', (
      t,
    ) async {
      await pump(t, const ProjectDetailPage(id: 'e1'));
      await t.tap(find.byKey(const ValueKey('billsSearch')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('billsTagFilter')));
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: find.byType(ItemPickerSheet),
          matching: find.text('Food'),
        ),
      );
      await t.pumpAndSettle();
      expect(repo.calls, ['detail e1', 'bills tag=t1 mine=false']);
      expect(find.text('Tagged bill'), findsOneWidget);
      expect(find.text('Dinner'), findsNothing);
      // "All" in the picker clears it without a call (the page's own board).
      await t.tap(find.byKey(const ValueKey('billsTagFilter')));
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: find.byType(ItemPickerSheet),
          matching: find.text('All'),
        ),
      );
      await t.pumpAndSettle();
      expect(repo.calls.length, 2);
      expect(find.text('Dinner'), findsOneWidget);
    });

    test('the payer filter is ONE server call with payer_member_id', () async {
      final repo = _Repo();
      final board = ProjectBoardController(repository: repo, projectId: 'e1');
      await board.change(payerId: 'm-lee');
      expect(repo.payers, ['m-lee']);
      expect(repo.calls, ['bills tag=null mine=false']);
      expect(board.serverFiltered, isTrue);
      await board.change(payerId: null);
      expect(repo.calls.length, 1);
      expect(board.rows, isNull);
      board.dispose();
    });

    testWidgets('network down → error + retry; retry loads it', (t) async {
      repo.networkDown = true;
      await pump(t, const ProjectDetailPage(id: 'e1'));
      expect(find.byType(ErrorView), findsOneWidget);
      repo.networkDown = false;
      await t.tap(find.text('Retry'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(ErrorView), findsNothing);
      expect(repo.calls, ['detail e1', 'detail e1']);
    });

    testWidgets('a malformed body → error, not an endless skeleton', (t) async {
      repo.detailBody = {'event': <String, dynamic>{}};
      await pump(t, const ProjectDetailPage(id: 'e1'));
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('?bill= (tx detail link) highlights that bill', (t) async {
      await pump(t, const ProjectDetailPage(id: 'e1', initialBillId: 'b2'));
      await t.pumpAndSettle();
      expect(repo.calls, ['detail e1']);
      expect(find.byType(EventBillRow), findsNWidgets(2));
      final rows = t.widgetList<EventBillRow>(find.byType(EventBillRow));
      expect(rows.where((r) => r.highlighted).map((r) => r.title), ['Dinner']);
    });

    testWidgets('bills have no tick boxes; my unbooked part is flagged', (
      t,
    ) async {
      await pump(t, const ProjectDetailPage(id: 'e1'));
      expect(
        find.descendant(
          of: find.byType(EventBillRow),
          matching: find.byType(SelectCheck),
        ),
        findsNothing,
      );
      expect(find.text('Not in my books'), findsWidgets);
    });
  });

  group('event edit / create', () {
    testWidgets('edit is its own form: totals, members, bills are hidden', (
      t,
    ) async {
      await pumpEdit(t);
      expect(find.byType(HeroAmountField), findsOneWidget);
      expect(find.text('Planned budget (optional)'), findsOneWidget);
      // The dates are a chip in the hero's bottom row, beside the status.
      expect(find.byKey(const ValueKey('eventDates')), findsOneWidget);
      expect(find.text('Manage event tags'), findsOneWidget);
      expect(find.text('1 tags'), findsOneWidget);
      // Hidden, not greyed.
      expect(find.text('Total spent'), findsNothing);
      expect(find.byType(PeopleStrip), findsNothing);
      expect(find.byType(EventBillRow), findsNothing);
      // The end zone: archive + delete.
      expect(find.byType(EndZone), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Delete this event'), findsOneWidget);
    });

    testWidgets('create: the same form with no end zone, no tags manager', (
      t,
    ) async {
      await pump(t, const ProjectDetailPage());
      expect(repo.calls, isEmpty);
      expect(find.byType(HeroAmountField), findsOneWidget);
      expect(find.byType(EndZone), findsNothing);
      expect(find.text('Manage event tags'), findsNothing);
    });

    testWidgets('archive: confirm → one call', (t) async {
      await pumpEdit(t);
      await t.ensureVisible(find.text('Archived'));
      await t.tap(find.text('Archived'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Archived').last);
      await t.pumpAndSettle();
      expect(repo.calls.last, 'archive e1');
    });

    testWidgets('Manage event tags opens the sheet with the shared tags', (
      t,
    ) async {
      await pumpEdit(t);
      await t.tap(find.text('Manage event tags'));
      await t.pumpAndSettle();
      expect(find.byType(EventTagsSheet), findsOneWidget);
      expect(find.text('Event tags | shared with members'), findsOneWidget);
      expect(find.text('Add event tag'), findsOneWidget);
    });

    group('delete (owner 2026-10-13)', () {
      Future<void> openDelete(WidgetTester t) async {
        repo.detailBody = detailJson();
        // /projects → /projects/e1: the page leaves to the list after a
        // delete.
        final router = GoRouter(
          initialLocation: '/projects/e1',
          routes: [
            GoRoute(
              path: '/projects',
              builder: (_, _) => const Scaffold(body: Text('events list')),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ProjectDetailPage(
                    id: state.pathParameters['id']!,
                    startEditing: true,
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await pump(t, const SizedBox(), router: router);
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Delete this event'));
        await t.tap(find.text('Delete this event'));
        await t.pumpAndSettle();
      }

      testWidgets('three choices; "delete and remove x" deletes the txs too', (
        t,
      ) async {
        await openDelete(t);
        // ONE preview call on the button; its numbers are in the dialog.
        expect(repo.calls, ['detail e1', 'preview e1']);
        expect(find.textContaining('3 bills and 2 members'), findsOneWidget);
        expect(find.text('Not now'), findsOneWidget);
        expect(find.text('Delete, keep my transactions'), findsOneWidget);
        await t.tap(find.text('Delete and remove 2 transactions'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(repo.calls.last, 'delete e1 txs=true');
        verify(() => accounts.patchBalances({'a1': 900})).called(1);
      });

      testWidgets('"not now" deletes nothing', (t) async {
        await openDelete(t);
        await t.tap(find.text('Not now'));
        await t.pumpAndSettle();
        expect(repo.calls.where((c) => c.startsWith('delete ')), isEmpty);
      });
    });
  });
}
