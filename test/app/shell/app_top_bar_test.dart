import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/app_top_bar.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

/// A list page pushes an edit-mode page while the "shell nav" under the
/// navigator collapses (what `EditModeMixin` does) — the navigator grows
/// mid hero flight. The left group must not move.
void main() {
  late ValueNotifier<bool> navHidden;
  late GlobalKey<NavigatorState> nav;

  Future<void> pumpApp(WidgetTester t) async {
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    t.view.padding = const FakeViewPadding(top: 72);
    t.view.viewPadding = const FakeViewPadding(top: 72);
    addTearDown(t.view.reset);
    navHidden = ValueNotifier(false);
    nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<PendingCubit>.value(value: pending),
          BlocProvider<UnreadBadgeCubit>.value(value: unread),
        ],
        child: MaterialApp(
          navigatorKey: nav,
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Stand-in for MainShell: a bottom nav that collapses.
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: navHidden,
            builder: (context, hidden, _) => Column(
              children: [
                Expanded(child: child!),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: hidden ? 0 : 96,
                ),
              ],
            ),
          ),
          home: const Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppTopBar(title: 'List', showBack: true),
            body: SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  /// Every frame's y of [title] (the flying copy, while there is one).
  Future<Set<double>> track(WidgetTester t, String title) async {
    final ys = <double>{};
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 20));
      final f = find.text(title);
      if (f.evaluate().isEmpty) continue;
      ys.add(t.getTopLeft(f.last).dy);
    }
    return ys;
  }

  testWidgets('push into edit mode while the nav hides — bar stays put', (
    t,
  ) async {
    await pumpApp(t);
    final rest = t.getTopLeft(find.text('List')).dy;
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppTopBar(title: 'New', editing: true),
          body: SizedBox.expand(),
        ),
      ),
    );
    await t.pump();
    navHidden.value = true;
    expect(await track(t, 'New'), {rest});
  });

  testWidgets('back out while the nav returns — bar stays put', (t) async {
    await pumpApp(t);
    final rest = t.getTopLeft(find.text('List')).dy;
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppTopBar(title: 'New', editing: true),
          body: SizedBox.expand(),
        ),
      ),
    );
    navHidden.value = true;
    await t.pumpAndSettle();
    nav.currentState!.pop();
    await t.pump();
    navHidden.value = false;
    expect(await track(t, 'List'), {rest});
  });

  testWidgets('titleSlot replaces the title; null falls back to it', (t) async {
    await pumpApp(t);
    final slotOn = ValueNotifier(true);
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ValueListenableBuilder<bool>(
          valueListenable: slotOn,
          builder: (_, on, _) => Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppTopBar(
              title: 'Edit',
              editing: true,
              titleSlot: on ? const Text('฿1,250') : null,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('฿1,250'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    // Back to the plain title — a cross-fade, then only the title.
    slotOn.value = false;
    await t.pump();
    await t.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('฿1,250'), findsNothing);
  });
}
