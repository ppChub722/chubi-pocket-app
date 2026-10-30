import 'package:chubi_pocket/app/shell/nav_layout.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:chubi_pocket/features/preferences/page_prefs.dart';
import 'package:chubi_pocket/features/settings/presentation/pages/settings_page_prefs_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const t = ShellTab.values;
  final d = NavLayout.defaults;

  test('the default layout is today’s shell', () {
    expect(d.bottomItems, [
      ShellTab.home,
      ShellTab.transactions,
      ShellTab.accounts,
      ShellTab.more,
    ]);
    expect(d.topItems, [
      ShellTab.pending,
      ShellTab.notifications,
      ShellTab.settings,
    ]);
    expect(
      [
        for (final g in d.moreGroups) [g.id, ...g.items],
      ],
      [
        [
          NavGroupId.planning,
          ShellTab.budgets,
          ShellTab.savingGoals,
          ShellTab.recurring,
        ],
        [NavGroupId.people, ShellTab.debts, ShellTab.projects],
        [
          NavGroupId.library,
          ShellTab.categories,
          ShellTab.tags,
          ShellTab.contacts,
        ],
      ],
    );
    expect(d.off, isEmpty);
    expect(t.where(d.isMoreOnly).toSet(), {for (final g in d.more) ...g.items});
  });

  test('swipe targets: along its own bar only, off modules skipped', () {
    final noNotif = d.withOff({ShellTab.notifications});
    final cases = <(String, NavLayout, NavBar, ShellTab, int, ShellTab?)>[
      ('bottom → next', d, NavBar.bottom, t[0], 1, ShellTab.transactions),
      ('bottom ← prev', d, NavBar.bottom, ShellTab.more, -1, ShellTab.accounts),
      ('bottom past the end', d, NavBar.bottom, ShellTab.more, 1, null),
      ('bottom before the start', d, NavBar.bottom, ShellTab.home, -1, null),
      (
        'top → next',
        d,
        NavBar.top,
        ShellTab.pending,
        1,
        ShellTab.notifications,
      ),
      ('top past the end', d, NavBar.top, ShellTab.settings, 1, null),
      (
        'top skips an off chip',
        noNotif,
        NavBar.top,
        t[4],
        1,
        ShellTab.settings,
      ),
      ('top bar on a bottom tab', d, NavBar.top, ShellTab.home, 1, null),
      ('bottom bar on a top tab', d, NavBar.bottom, ShellTab.pending, 1, null),
      ('bottom bar on a More page', d, NavBar.bottom, ShellTab.debts, -1, null),
      ('top bar on a More page', d, NavBar.top, ShellTab.budgets, 1, null),
      ('no step', d, NavBar.bottom, ShellTab.home, 0, null),
    ];
    for (final (name, layout, bar, from, step, want) in cases) {
      expect(layout.swipeTarget(bar, from, step), want, reason: name);
    }
  });

  test('a module that is off is gone from bars, chips and More', () {
    final off = d.withOff({
      ShellTab.pending,
      ShellTab.debts,
      ShellTab.projects,
    });
    expect(off.topItems, [ShellTab.notifications, ShellTab.settings]);
    expect(off.barOf(ShellTab.pending), isNull);
    expect(off.moreGroups.map((g) => g.id), [
      NavGroupId.planning,
      NavGroupId.library,
    ]);
    expect(offModuleRedirect('/personal-debts', layout: off), '/more');
  });

  test('settings › ตัวกรองและการเรียง: an off module’s row is disabled', () {
    final pages = [for (final g in pagePrefGroups) ...g.pages];
    final budgets = pages.firstWhere((p) => p.id == 'budgets');
    final events = pages.firstWhere((p) => p.id == 'events');
    final dashboard = pages.firstWhere((p) => p.id == 'dashboard');
    expect(pagePrefRowEnabled(budgets, d), isTrue);
    expect(pagePrefRowEnabled(dashboard, d), isFalse, reason: 'soon');
    final off = d.withOff({ShellTab.budgets, ShellTab.projects});
    expect(pagePrefRowEnabled(budgets, off), isFalse);
    expect(pagePrefRowEnabled(events, off), isFalse);
    // Every other row stays on.
    for (final p in pages) {
      if (p.soon || p == budgets || p == events) continue;
      expect(pagePrefRowEnabled(p, off), isTrue, reason: p.id);
    }
  });
}
