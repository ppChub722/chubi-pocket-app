import 'package:chubi_pocket/app/shell/nav_layout.dart';
import 'package:chubi_pocket/app/shell/tab_entry.dart';
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
  test('a switch starts the tab over, a back keeps it, the open tab replays', () {
    final calls = <String>[];
    void go(int i, {bool initialLocation = false}) =>
        calls.add('$i:$initialLocation');
    const to = ShellTab.accounts;

    goTab(to, from: ShellTab.home.index, goBranch: go, canPop: (_) => false);
    expect(calls.removeLast(), '${to.index}:true', reason: 'starts over');

    goTab(to, from: ShellTab.home.index, goBranch: go, back: true);
    expect(calls.removeLast(), '${to.index}:false', reason: 'a back keeps it');

    goTab(to, from: to.index, goBranch: go, canPop: (_) => false);
    expect(calls, isEmpty, reason: 'already on its first page: nothing');

    final before = ShellReopen.signal.value;
    goTab(to, from: to.index, goBranch: go, canPop: (_) => true);
    expect(calls.removeLast(), '${to.index}:true');
    expect(ShellReopen.signal.value, before + 1, reason: 'the entry replays');
  });
}
