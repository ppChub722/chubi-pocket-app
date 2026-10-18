import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/pages/category_detail_page.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

/// The shape the server sends (list + detail carry the month figures).
final _prodJson = <String, dynamic>{
  'id': 'cat1',
  'name': 'Food',
  'type': 'expense',
  'include_in_report': true,
  'month_spent': 5100,
  'month_count': 12,
};

void main() {
  late _Categories categories;
  late QuickCreateContext registry;

  Future<void> pump(WidgetTester t, Widget page, {GoRouter? router}) async {
    registry = QuickCreateContext();
    addTearDown(registry.dispose);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<PendingCubit>.value(value: pending),
          BlocProvider<UnreadBadgeCubit>.value(value: unread),
          BlocProvider<CategoriesCubit>.value(value: categories),
        ],
        child: Builder(
          builder: (context) {
            final theme = ThemeData(extensions: [sweetTheme.lightColors]);
            Widget wrap(BuildContext context, Widget? child) => AppUiConfig(
              child: QuickCreateContextScope(registry: registry, child: child!),
            );
            return router == null
                ? MaterialApp(
                    theme: theme,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: const Locale('en'),
                    builder: wrap,
                    home: page,
                  )
                : MaterialApp.router(
                    theme: theme,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: const Locale('en'),
                    builder: wrap,
                    routerConfig: router,
                  );
          },
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  void arrange({
    Future<CategoryDetail> Function()? detail,
    Map<String, dynamic>? json,
  }) {
    final row = Category.fromJson(json ?? _prodJson);
    when(() => categories.state).thenReturn(
      CategoriesState(categories: [row], status: CategoriesStatus.loaded),
    );
    when(() => categories.byId(row.id)).thenReturn(row);
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    when(() => categories.canAddMore).thenReturn(true);
    when(() => categories.fetchDetail(any())).thenAnswer(
      (_) =>
          (detail ?? () async => CategoryDetail.fromJson(json ?? _prodJson))(),
    );
  }

  /// A child row whose parent is NOT in the cubit's list; the detail
  /// carries the whole path.
  final childJson = <String, dynamic>{
    'id': 'cat2',
    'name': 'Lunch',
    'type': 'expense',
    'parent_id': 'p2',
    'include_in_report': true,
    'month_spent': 0,
    'month_count': 0,
    'path': [
      {
        'id': 'p1',
        'name': 'Eating Out',
        'icon_code': {'icon': 'food', 'color': 'orange'},
      },
      {'id': 'p2', 'name': 'Restaurants'},
    ],
  };

  setUpAll(() => registerFallbackValue(Category.fromJson(_prodJson)));
  setUp(() => categories = _Categories());

  testWidgets('model: month figures parse, absent = 0', (t) async {
    final c = Category.fromJson(_prodJson);
    expect(c.monthSpent, 5100);
    expect(c.monthCount, 12);
    final bare = Category.fromJson({'id': 'x', 'name': 'x', 'type': 'income'});
    expect(bare.monthSpent, 0);
    expect(bare.monthCount, 0);
  });

  testWidgets('view mode shows the month number row', (t) async {
    arrange();
    await pump(t, const CategoryDetailPage(editingId: 'cat1'));
    expect(find.byType(HeroNumber), findsOneWidget);
    expect(find.textContaining('12 transactions'), findsOneWidget);
    expect(find.textContaining('5,100'), findsOneWidget);
    expect(find.byType(EndZone), findsNothing);
    expect(find.byType(InfoBox), findsOneWidget);
    expect(find.byType(NoteSection), findsOneWidget);
  });

  testWidgets('create mode has no number and no end zone', (t) async {
    arrange();
    await pump(t, const CategoryDetailPage());
    expect(find.byType(HeroNumber), findsNothing);
    expect(find.byType(EndZone), findsNothing);
    expect(find.byType(OptionMenuAnchor<dynamic>), findsNothing);
    expect(find.byType(HeroNameInput), findsOneWidget);
  });

  testWidgets('view toggle saves at once with one update', (t) async {
    arrange();
    when(() => categories.update(any())).thenAnswer((inv) async {
      final c = inv.positionalArguments.first as Category;
      return CategoryDetail.fromCategory(c);
    });
    await pump(t, const CategoryDetailPage(editingId: 'cat1'));
    await t.tap(find.byType(AppSwitch).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    final sent =
        verify(() => categories.update(captureAny())).captured.single
            as Category;
    expect(sent.includeInReport, isFalse);
    expect(sent.name, 'Food');
  });

  testWidgets('view toggle reverts when the save fails', (t) async {
    arrange();
    when(() => categories.update(any())).thenThrow(
      const ApiException(code: 'INTERNAL', message: 'boom', statusCode: 500),
    );
    await pump(t, const CategoryDetailPage(editingId: 'cat1'));
    await t.tap(find.byType(AppSwitch).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    verify(() => categories.update(any())).called(1);
    final sw = t.widget<AppSwitch>(find.byType(AppSwitch).first);
    expect(sw.value, isTrue);
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('edit mode hides the number and shows the delete end zone', (
    t,
  ) async {
    arrange();
    await pump(t, const CategoryDetailPage(editingId: 'cat1'));
    await t.tap(find.byType(CardActionButton));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(HeroNumber), findsNothing);
    expect(find.byType(EndZone), findsOneWidget);
    expect(find.text('Delete category'), findsOneWidget);
  });

  testWidgets('a failing detail load keeps the cached row working', (t) async {
    arrange(
      detail: () async =>
          throw const ApiException(code: 'NETWORK', message: 'offline'),
    );
    await pump(t, const CategoryDetailPage(editingId: 'cat1'));
    expect(find.byType(AppHeroCard), findsOneWidget);
    // Figures from the list row still show.
    expect(find.textContaining('12 transactions'), findsOneWidget);
  });

  testWidgets('parent chip comes from the detail path, not the list', (
    t,
  ) async {
    // The list holds only the child row — no parent rows at all.
    arrange(json: childJson);
    await pump(t, const CategoryDetailPage(editingId: 'cat2'));
    expect(find.byType(ChipPath), findsOneWidget);
    final chip = t.widget<ChipPath>(find.byType(ChipPath));
    expect(chip.segments.map((s) => s.label), ['Eating Out', 'Restaurants']);
    expect(chip.segments.first.icon, isNotNull);
  });

  testWidgets('a server 422 duplicate shows on the name field', (t) async {
    arrange();
    when(() => categories.update(any())).thenThrow(
      const ApiException(
        code: 'CATEGORY_NAME_DUPLICATE',
        message: 'duplicate',
        statusCode: 422,
        details: {'field': 'name'},
      ),
    );
    await pump(t, const CategoryDetailPage(editingId: 'cat1'));
    await t.tap(find.byType(CardActionButton));
    await t.pump(const Duration(milliseconds: 300));
    // No client-side check: nothing shown before the server answers.
    const dup = 'Another category at this level already uses this name';
    await t.enterText(find.byType(TextFormField).first, 'Drinks');
    await t.pump();
    expect(find.text(dup), findsNothing);
    await t.tap(find.text('Save'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    verify(() => categories.update(any())).called(1);
    expect(find.text(dup), findsOneWidget);
    expect(find.text('duplicate'), findsNothing);
  });

  testWidgets('the old 400 DUPLICATE_NAME maps the same way', (t) async {
    arrange();
    when(() => categories.update(any())).thenThrow(
      const ApiException(
        code: 'DUPLICATE_NAME',
        message: 'dup',
        statusCode: 400,
      ),
    );
    await pump(t, const CategoryDetailPage(editingId: 'cat1'));
    await t.tap(find.byType(CardActionButton));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(find.byType(TextFormField).first, 'Drinks');
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(
      find.text('Another category at this level already uses this name'),
      findsOneWidget,
    );
  });

  testWidgets('an income category label opens browse with type=income', (
    t,
  ) async {
    final income = {..._prodJson, 'id': 'inc1', 'type': 'income'};
    arrange(json: income);
    Uri? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const CategoryDetailPage(editingId: 'inc1'),
        ),
        GoRoute(
          path: '/browse',
          builder: (_, state) {
            opened = state.uri;
            return const Scaffold(body: Text('browse'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await pump(t, const SizedBox(), router: router);
    final number = t.widget<HeroNumber>(find.byType(HeroNumber));
    expect(number.onLabelTap, isNotNull);
    number.onLabelTap!();
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(opened?.queryParameters['type'], 'income');
    expect(opened?.queryParameters['category'], 'inc1');
  });
}
