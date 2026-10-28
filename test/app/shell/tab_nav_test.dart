import 'package:chubi_pocket/app/shell/nav_layout.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every tab sits in exactly one place of the default layout, all on', () {
    final d = NavLayout.defaults;
    for (final tab in ShellTab.values) {
      final places = [
        if (d.bottom.contains(tab)) 'bottom',
        if (d.top.contains(tab)) 'top',
        for (final g in d.more)
          if (g.items.contains(tab)) g.id.name,
      ];
      expect(places, hasLength(1), reason: '$tab');
      expect(d.isOn(tab), isTrue, reason: '$tab');
    }
  });

  test('a tab path leads back to its tab', () {
    for (final tab in ShellTab.values) {
      expect(ShellTab.ofPath(tab.path), tab, reason: tab.path);
    }
  });
  test('which tab switches land on the first page', () {
    final t = ShellTab.values;
    // Only the profile / settings tab forgets its stack when left.
    expect(t.where((tab) => tab.resetsOnReturn), [ShellTab.settings]);
    final cases = <(String, ShellTab, ShellTab, bool)>[
      (
        'a nav tab keeps its stack',
        ShellTab.transactions,
        ShellTab.home,
        false,
      ),
      (
        'settings → กระเป๋า keeps it',
        ShellTab.settings,
        ShellTab.accounts,
        false,
      ),
      ('เพิ่มเติม keeps its stack', ShellTab.home, ShellTab.more, false),
      ('a card tab keeps its stack', ShellTab.more, ShellTab.budgets, false),
      ('a top chip keeps its stack', ShellTab.home, ShellTab.pending, false),
      (
        'settings from a nav tab',
        ShellTab.transactions,
        ShellTab.settings,
        true,
      ),
      ('settings from a chip', ShellTab.notifications, ShellTab.settings, true),
      ('settings from a card tab', ShellTab.budgets, ShellTab.settings, true),
      ('tap the open nav tab', ShellTab.accounts, ShellTab.accounts, true),
      ('tap the open เพิ่มเติม', ShellTab.more, ShellTab.more, true),
      ('tap the open chip', ShellTab.pending, ShellTab.pending, true),
      ('tap the open avatar', ShellTab.settings, ShellTab.settings, true),
    ];
    for (final (name, from, to, root) in cases) {
      expect(to.opensAtRootFrom(from), root, reason: name);
    }
    // Every other switch keeps the arriving tab's stack.
    for (final from in t) {
      for (final to in t) {
        if (from == to || to == ShellTab.settings) continue;
        expect(to.opensAtRootFrom(from), isFalse, reason: '$from → $to');
      }
    }
  });
}
