import 'package:chubi_pocket/ui/tokens/app/app_colors.dart';
import 'dart:ui' as ui;

import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Every route — a tab page, a full-screen route pushed on the ROOT
/// navigator, a dialog, a sheet — sits under the app's ONE theme: with the
/// dark mode on, each paints the dark scaffold colour (a page that renders
/// light while the rest is dark is a bug in the page, not in the route).
void main() {
  testWidgets('routes on the root navigator, dialogs and sheets are dark', (
    t,
  ) async {
    final key = GlobalKey();
    final rootKey = GlobalKey<NavigatorState>();
    // The app's theme, built without the web fonts (no network in tests).
    ThemeData build(Brightness b, PpForgeColors c) => ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: c.toColorScheme(),
      scaffoldBackgroundColor: c.background,
      extensions: [c],
    );
    final dark = build(Brightness.dark, sweetTheme.darkColors);
    final router = GoRouter(
      navigatorKey: rootKey,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/full'),
                child: const Text('go'),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'full',
              parentNavigatorKey: rootKey,
              builder: (context, _) =>
                  const Scaffold(body: Center(child: Text('full-screen'))),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp.router(
          theme: build(Brightness.light, sweetTheme.lightColors),
          darkTheme: dark,
          themeMode: ThemeMode.dark,
          routerConfig: router,
        ),
      ),
    );
    await t.pumpAndSettle();

    Future<void> expectDark(String where) async {
      final ctx = t.element(find.byType(Scaffold).last);
      expect(Theme.of(ctx).brightness, Brightness.dark, reason: where);
      final image = (await t.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return b.toImage(pixelRatio: 1);
      }))!;
      final data = (await t.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      // A corner pixel (nothing but the scaffold paints there).
      final o = (10 * image.width + 10) * 4;
      final want = dark.scaffoldBackgroundColor;
      expect(data.getUint8(o), (want.r * 255).round(), reason: '$where: R');
      expect(data.getUint8(o + 1), (want.g * 255).round(), reason: '$where: G');
      expect(data.getUint8(o + 2), (want.b * 255).round(), reason: '$where: B');
    }

    await expectDark('home route');
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('full-screen'), findsOneWidget);
    await expectDark('route pushed on the root navigator');

    final nav = rootKey.currentState!;
    // ignore: unawaited_futures
    showDialog<void>(
      context: nav.context,
      builder: (_) => const AlertDialog(content: Text('dlg')),
    );
    await t.pumpAndSettle();
    expect(
      Theme.of(t.element(find.text('dlg'))).brightness,
      Brightness.dark,
      reason: 'dialog',
    );
    Navigator.of(t.element(find.text('dlg'))).pop();
    await t.pumpAndSettle();
    // ignore: unawaited_futures
    showModalBottomSheet<void>(
      context: nav.context,
      builder: (_) => const SizedBox(height: 80, child: Text('sheet')),
    );
    await t.pumpAndSettle();
    expect(
      Theme.of(t.element(find.text('sheet'))).brightness,
      Brightness.dark,
      reason: 'sheet',
    );
  });
}
