import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/data/saving_goals_repository.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goals_overview.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/pages/saving_goal_detail_page.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/pages/saving_goals_list_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'saving_goal_parse_test.dart' show prodDetail, prodList;

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

/// Runs the REAL model parsing on prod-shaped JSON, or fails like the network.
class _Repo extends Fake implements SavingGoalsRepository {
  bool networkDown = false;
  int listCalls = 0;
  int detailCalls = 0;

  void _check() {
    if (networkDown) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no connection');
    }
  }

  @override
  Future<SavingGoalsOverview> list({String status = 'active'}) async {
    listCalls++;
    _check();
    return SavingGoalsOverview.fromJson(prodList());
  }

  @override
  Future<SavingGoalDetail> detail(String id) async {
    detailCalls++;
    _check();
    return SavingGoalDetail.fromJson(prodDetail());
  }
}

void main() {
  late _Repo repo;
  late QuickCreateContext registry;

  setUp(() {
    repo = _Repo();
    registry = QuickCreateContext();
  });

  tearDown(() => registry.dispose());

  Future<void> pump(WidgetTester t, Widget home) async {
    // Tall view: the page is a lazy ListView.
    t.view.physicalSize = const Size(800, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    await t.pumpWidget(
      RepositoryProvider<SavingGoalsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<SavingGoalsCubit>(
              create: (_) => SavingGoalsCubit(repository: repo),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                ThemeRegistry.byId(
                  ThemeRegistry.defaultThemeId,
                ).colorsFor(Brightness.light),
              ],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(
              child: QuickCreateContextScope(registry: registry, child: child!),
            ),
            home: home,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('list: prod-shaped JSON shows the totals, spare and the goal', (
    t,
  ) async {
    await pump(t, const SavingGoalsListPage());
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
    expect(find.text('Not allocated'), findsWidgets);
    expect(find.text('Saved in total'), findsOneWidget);
    expect(repo.listCalls, 1);
  });

  testWidgets('list: a failed first load is a full-page error', (t) async {
    repo.networkDown = true;
    await pump(t, const SavingGoalsListPage());
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('ทริปญี่ปุ่น'), findsNothing);
  });

  testWidgets('detail: ONE call on open; shows by-wallet and entries', (
    t,
  ) async {
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(repo.detailCalls, 1);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('ทริปญี่ปุ่น'), findsWidgets);
    expect(find.text('กสิกร'), findsWidgets);
    expect(find.text('Saving entries'), findsOneWidget);
  });

  testWidgets('detail: a failed load is a full-page error', (t) async {
    repo.networkDown = true;
    await pump(t, const SavingGoalDetailPage(id: 'g1'));
    expect(find.byType(ErrorView), findsOneWidget);
  });
}
