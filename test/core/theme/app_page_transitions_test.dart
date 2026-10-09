import 'package:chubi_pocket/app/shell/fade_branch_container.dart';
import 'package:chubi_pocket/core/theme/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Mirrors the app's shell: root navigator + StatefulShellRoute whose
/// branches live in [FadeBranchContainer].
class _Harness {
  final rootKey = GlobalKey<NavigatorState>();
  late StatefulNavigationShell shell;

  late final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/a',
    routes: [
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) =>
            FadeBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        builder: (context, state, navigationShell) {
          shell = navigationShell;
          return Scaffold(body: navigationShell);
        },
        branches: [_branch('a'), _branch('b')],
      ),
    ],
  );

  static StatefulShellBranch _branch(String name) => StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/$name',
        builder: (_, _) => Scaffold(body: Text('$name root')),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (_, _) => Scaffold(body: Text('$name detail')),
          ),
        ],
      ),
    ],
  );

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {TargetPlatform.android: AppPageTransitionsBuilder()},
          ),
        ),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    showModalBottomSheet<void>(
      context: rootKey.currentContext!,
      builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
    );
    await tester.pumpAndSettle();
  }
}

/// A full Android predictive back swipe: start → drag → commit.
Future<void> _swipeBack(WidgetTester tester) async {
  Future<void> send(MethodCall call) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        const StandardMethodCodec().encodeMethodCall(call),
        (_) {},
      );
  await send(
    const MethodCall('startBackGesture', {
      'touchOffset': [5.0, 300.0],
      'progress': 0.0,
      'swipeEdge': 0,
    }),
  );
  await tester.pump();
  await send(
    const MethodCall('updateBackGestureProgress', {
      'x': 100.0,
      'y': 300.0,
      'progress': 0.35,
      'swipeEdge': 0,
    }),
  );
  await tester.pump();
  await send(const MethodCall('commitBackGesture'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('swipe back pops the visible page', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    h.router.go('/a/detail');
    await tester.pumpAndSettle();

    await _swipeBack(tester);

    expect(find.text('a detail'), findsNothing);
    expect(find.text('a root'), findsOneWidget);
  });

  testWidgets('swipe back closes a root sheet, not the page under it', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    h.router.go('/a/detail');
    await tester.pumpAndSettle();
    await h.openSheet(tester);

    await _swipeBack(tester);

    expect(find.text('sheet'), findsNothing);
    expect(find.text('a detail'), findsOneWidget);
  });

  testWidgets('swipe back leaves a hidden tab\'s stack alone', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    h.router.go('/b/detail');
    await tester.pumpAndSettle();
    h.shell.goBranch(0);
    await tester.pumpAndSettle();
    await h.openSheet(tester);

    await _swipeBack(tester);
    expect(find.text('sheet'), findsNothing);

    // Nothing left to pop on tab a — the gesture must not reach tab b.
    await _swipeBack(tester);

    h.shell.goBranch(1);
    await tester.pumpAndSettle();
    expect(find.text('b detail'), findsOneWidget);
  });
}
