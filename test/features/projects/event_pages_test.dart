import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/projects_cubit.dart';
import 'package:chubi_pocket/features/projects/presentation/pages/project_detail_page.dart';
import 'package:chubi_pocket/features/projects/presentation/pages/projects_page.dart';
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

/// Runs the REAL model parsing on spec-shaped bodies, or fails like the
/// network does. Counts the calls (thin FE: one per open / button).
class _Repo extends Fake implements ProjectsRepository {
  bool networkDown = false;
  Map<String, dynamic>? detailBody;
  final calls = <String>[];

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
    _net();
    return ProjectPage(
      projects: [
        Project.fromJson(
          eventJson(
            tags: [
              {'id': 'pt1', 'name': 'Trips', 'icon_code': null},
            ],
          ),
        ),
        Project.fromJson(eventJson(id: 'e2', name: 'Office party')),
      ],
      page: page,
      totalPages: 1,
    );
  }

  @override
  Future<ProjectDetail> detail(String id, {int perPage = 50}) async {
    calls.add('detail $id');
    _net();
    return ProjectDetail.fromJson(detailBody ?? detailJson());
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
  });

  tearDown(() => projects.close());

  /// [home], or a [router] when the page leaves itself (delete).
  Future<void> pump(WidgetTester t, Widget home, {GoRouter? router}) async {
    // A tall phone: the hero, the tab bar and the tab body all fit.
    t.view.physicalSize = const Size(420, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
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

  group('events list', () {
    testWidgets('one call on open; rows on EventCard with my tags', (t) async {
      await pump(t, const ProjectsPage());
      expect(repo.calls, ['list q= page=1']);
      expect(find.byType(EventCard), findsNWidgets(2));
      expect(find.text('Chiang Mai trip'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
    });

    testWidgets('search runs on the server (debounced, one call)', (t) async {
      await pump(t, const ProjectsPage());
      await t.enterText(find.byType(TextField).first, 'trip');
      await t.pump(const Duration(milliseconds: 400));
      await t.pump();
      expect(repo.calls.last, 'list q=trip page=1');
      expect(repo.calls.length, 2);
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
      expect(find.byType(EventCard), findsNWidgets(2));
    });
  });

  group('event page', () {
    testWidgets('one call on open (the detail endpoint)', (t) async {
      await pump(t, const ProjectDetailPage(id: 'e1'));
      expect(repo.calls, ['detail e1']);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Chiang Mai trip'), findsWidgets);
      // สรุป: who paid + top tags from the BE summary.
      expect(find.byType(PositionRow), findsWidgets);
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

    testWidgets('?bill= (tx detail link) opens on รายการ with that bill', (
      t,
    ) async {
      await pump(t, const ProjectDetailPage(id: 'e1', initialBillId: 'b2'));
      await t.pumpAndSettle();
      expect(repo.calls, ['detail e1']);
      expect(find.byType(EventBillRow), findsNWidgets(2));
      expect(find.text('Dinner'), findsOneWidget);
      final rows = t.widgetList<EventBillRow>(find.byType(EventBillRow));
      expect(rows.where((r) => r.highlighted).map((r) => r.title), ['Dinner']);
    });

    group('delete (owner 2026-10-13)', () {
      Future<void> openDelete(WidgetTester t) async {
        repo.detailBody = detailJson(linkedTxCount: 2);
        // /projects → /projects/e1: the page leaves to the list after a
        // delete (its "deleted" snackbar lands on the list's Scaffold).
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
        expect(find.text('Not now'), findsOneWidget);
        expect(find.text('Delete, keep my transactions'), findsOneWidget);
        await t.tap(find.text('Delete and remove 2 transactions'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(repo.calls.last, 'delete e1 txs=true');
        // The deleted transactions' wallets, from the answer (no reload).
        verify(() => accounts.patchBalances({'a1': 900})).called(1);
      });

      testWidgets('"keep my transactions" deletes the event only', (t) async {
        await openDelete(t);
        await t.tap(find.text('Delete, keep my transactions'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(repo.calls.last, 'delete e1 txs=false');
      });

      testWidgets('"not now" deletes nothing', (t) async {
        await openDelete(t);
        await t.tap(find.text('Not now'));
        await t.pumpAndSettle();
        expect(repo.calls.where((c) => c.startsWith('delete ')), isEmpty);
      });
    });

    testWidgets('a linked bill: 🔗 stays, no "edits change both" wording', (
      t,
    ) async {
      final l = lookupAppLocalizations(const Locale('en'));
      await pump(t, const ProjectDetailPage(id: 'e1'));
      await t.tap(find.text('Transactions').first);
      await t.pumpAndSettle();
      final linked = t
          .widgetList<EventBillRow>(find.byType(EventBillRow))
          .where((r) => r.linked);
      expect(linked.map((r) => r.title), ['Gas']);
      await t.tap(find.text('Gas'));
      await t.pumpAndSettle();
      expect(find.text(l.projectTxEdit), findsOneWidget);
      expect(find.text(l.eventBillLinkedMoneyHint), findsNothing);
      expect(find.text(l.txLinkedMoneyHint), findsNothing);
    });

    testWidgets('a tick is one call; its patch is applied (no reload)', (
      t,
    ) async {
      await pump(t, const ProjectDetailPage(id: 'e1'));
      // The รายการ tab.
      await t.tap(find.text('Transactions').first);
      await t.pumpAndSettle();
      final row = find.byType(EventBillRow).last; // b2: not mine to resolve
      expect(row, findsOneWidget);
      final tick = find.descendant(of: row, matching: find.byType(SelectCheck));
      await t.tap(tick.first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(repo.calls, ['detail e1', 'mark b2 true']);
    });
  });
}
