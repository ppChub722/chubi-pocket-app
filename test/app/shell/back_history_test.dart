import 'package:chubi_pocket/app/shell/back_history.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Case = ({
  String name,
  List<(ShellTab, ShellTab)> visits,
  ShellTab at,
  List<int?> backs,
});

void main() {
  test('back on a tab root', () {
    final cases = <_Case>[
      (
        name: 'walks the tabs visited, newest first, then asks to exit',
        visits: [
          (ShellTab.home, ShellTab.transactions),
          (ShellTab.transactions, ShellTab.accounts),
        ],
        at: ShellTab.accounts,
        backs: [ShellTab.transactions.index, ShellTab.home.index, null],
      ),
      (
        name: 'no history: a nav tab → the dashboard',
        visits: [],
        at: ShellTab.accounts,
        backs: [ShellTab.home.index, null],
      ),
      (
        name: 'no history: a เพิ่มเติม card → the hub → the dashboard',
        visits: [],
        at: ShellTab.projects,
        backs: [ShellTab.more.index, ShellTab.home.index, null],
      ),
      (
        name: 'revisiting a tab moves it to the newest',
        visits: [
          (ShellTab.home, ShellTab.transactions),
          (ShellTab.transactions, ShellTab.accounts),
          (ShellTab.accounts, ShellTab.transactions),
        ],
        at: ShellTab.transactions,
        backs: [ShellTab.accounts.index, ShellTab.home.index, null],
      ),
    ];
    for (final c in cases) {
      final history = ShellBackHistory();
      for (final (from, to) in c.visits) {
        history.branchChanged(from.index, to.index);
      }
      var at = c.at;
      final got = <int?>[];
      for (var i = 0; i < c.backs.length; i++) {
        final to = history.backTarget(at);
        got.add(to);
        if (to == null) break;
        history.branchChanged(at.index, to);
        at = ShellTab.values[to];
      }
      expect(got, c.backs, reason: c.name);
    }
  });

  test('a predictive back peeks first, takes only on commit', () {
    final history = ShellBackHistory()
      ..branchChanged(ShellTab.home.index, ShellTab.notifications.index);
    expect(history.peekBackTarget(ShellTab.notifications), 0);
    expect(history.peekBackTarget(ShellTab.notifications), 0);
    expect(history.backTarget(ShellTab.notifications), 0);
    history.branchChanged(ShellTab.notifications.index, 0);
    expect(history.peekBackTarget(ShellTab.home), isNull);
  });
}
