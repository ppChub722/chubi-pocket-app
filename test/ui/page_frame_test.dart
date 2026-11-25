import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One page frame (owner 2026-11-25): every screen with a top bar is an
/// `AppPage` (the kit's `PpForgePage`), so its body runs under the top bar and
/// clears it inside its own scroll padding. No page builds a bare Scaffold,
/// and nothing is pinned under the bar: the compact hero and the tabs float
/// back as an overlay (`CompactHeroScope`), so the content scrolls on under
/// them.
void main() {
  /// Screens without a top bar (full screen), and the shell itself.
  const allowScaffold = {
    'lib/app/boot_error_app.dart',
    'lib/app/shell/main_shell.dart',
    'lib/features/auth/presentation/pages/login_page.dart',
    'lib/features/auth/presentation/pages/splash_page.dart',
    'lib/features/app_version/presentation/pages/update_required_page.dart',
  };

  Iterable<File> sources() sync* {
    for (final dir in ['lib/features', 'lib/app']) {
      for (final f in Directory(dir).listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) yield f;
      }
    }
  }

  String rel(File f) => f.path.replaceAll('\\', '/');

  test('every page is an AppPage, not a bare Scaffold', () {
    final scaffold = RegExp(r'(?<![\w.])Scaffold\(');
    final hits = [
      for (final f in sources())
        if (!allowScaffold.contains(rel(f)) &&
            scaffold.hasMatch(f.readAsStringSync()))
          rel(f),
    ];
    expect(hits, isEmpty, reason: 'use AppPage (app/shell/app_page.dart)');
  });

  test('nothing is pinned under the top bar', () {
    final pinned = RegExp(r'PinnedTabBarDelegate|SliverPersistentHeader\(');
    final hits = [
      for (final f in sources())
        if (pinned.hasMatch(f.readAsStringSync())) rel(f),
    ];
    expect(
      hits,
      isEmpty,
      reason:
          'tabs scroll away and float back (TabbedDetailBody / '
          'TabbedListPageBody / CompactHeroScope)',
    );
  });
}
