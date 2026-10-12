import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/app_top_bar.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

/// The top SCRIM (owner 2026-10-12): a gradient behind the transparent
/// AppTopBar — the app background over the status-bar inset, fading out across
/// the bar — so scrolled content never shows under the clock / behind the
/// floating pills. Same bar, same scrim on every list and detail page.
void main() {
  // 72 physical px of status bar.
  const physicalInset = 72.0;

  Future<void> pumpPage(
    WidgetTester t, {
    required Brightness brightness,
    required Widget body,
  }) async {
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    t.view.padding = const FakeViewPadding(top: physicalInset);
    t.view.viewPadding = const FakeViewPadding(top: physicalInset);
    addTearDown(t.view.reset);
    final colors = brightness == Brightness.dark
        ? sweetTheme.darkColors
        : sweetTheme.lightColors;
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<PendingCubit>.value(value: pending),
          BlocProvider<UnreadBadgeCubit>.value(value: unread),
        ],
        child: MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            scaffoldBackgroundColor: colors.background,
            extensions: [colors],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: const AppTopBar(title: 'Page', showBack: true),
            body: body,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    for (final kind in const ['list', 'detail']) {
      testWidgets('scrim on a $kind page · ${brightness.name}', (t) async {
        var taps = 0;
        final rows = [
          for (var i = 0; i < 30; i++)
            ListTile(title: Text('row $i'), onTap: () => taps++),
        ];
        await pumpPage(
          t,
          brightness: brightness,
          body: kind == 'list'
              ? ListView(children: rows)
              : CustomScrollView(slivers: [SliverList.list(children: rows)]),
        );
        final scrim = find.byKey(AppTopBar.scrimKey);
        final inset = MediaQuery.paddingOf(t.element(scrim)).top;
        expect(inset, greaterThan(0));
        expect(scrim, findsOneWidget);
        final box = t.getRect(scrim);
        expect(box.top, 0);
        expect(
          box.height,
          inset + kToolbarHeight,
          reason: 'status-bar inset + bar height',
        );
        final gradient =
            (t
                            .widget<DecoratedBox>(
                              find.descendant(
                                of: scrim,
                                matching: find.byType(DecoratedBox),
                              ),
                            )
                            .decoration
                        as BoxDecoration)
                    .gradient!
                as LinearGradient;
        final bg = Theme.of(t.element(scrim)).scaffoldBackgroundColor;
        expect(gradient.colors.first, bg, reason: 'solid app background');
        expect(gradient.colors.last.a, 0, reason: 'fades to transparent');
        expect(gradient.stops!.first, 0);
        expect(
          gradient.stops![1],
          closeTo(inset / (inset + kToolbarHeight), 1e-6),
          reason: 'solid across the status bar',
        );

        // The fade does not eat touches: a row under the lower band is still
        // tappable, and a drag that starts in it scrolls the list.
        // (A row's centre at y = 130 sits inside the band, below the pills' y.)
        await t.tapAt(const Offset(200, 130));
        expect(taps, greaterThan(0), reason: 'content under the fade is live');
        final before = t.getTopLeft(find.text('row 5')).dy;
        await t.dragFrom(const Offset(200, 120), const Offset(0, -80));
        await t.pumpAndSettle();
        expect(t.getTopLeft(find.text('row 5')).dy, lessThan(before));
      });
    }
  }
}
