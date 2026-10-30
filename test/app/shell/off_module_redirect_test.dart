import 'package:chubi_pocket/app/shell/nav_layout.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter_test/flutter_test.dart';

/// A module that's off (NavLayout.off) has no pages: the router sends any
/// way in — deep link, notification link, openPage — somewhere safe.
void main() {
  NavLayout off(Set<ShellTab> tabs) => NavLayout.defaults.withOff(tabs);
  final allOn = off({});
  final allOff = off(ShellTab.values.toSet());

  test('redirect table', () {
    final cases = <(String, NavLayout, String?)>[
      ('/projects/1', allOn, null),
      ('/pending', allOn, null),
      ('/projects', off({ShellTab.projects}), '/more'),
      ('/projects/abc/members', off({ShellTab.projects}), '/more'),
      ('/contacts/1', off({ShellTab.projects}), null),
      ('/pending/new', off({ShellTab.pending}), '/'),
      ('/notifications', off({ShellTab.notifications}), '/'),
      ('/settings/notifications', off({ShellTab.notifications}), '/'),
      ('/settings/profile', off({ShellTab.notifications}), null),
      ('/dev/widgets', allOff, null),
      ('/auth/login', allOff, null),
    ];
    for (final (path, layout, want) in cases) {
      expect(offModuleRedirect(path, layout: layout), want, reason: path);
    }
  });

  test('with the real switches, every core tab stays reachable', () {
    for (final path in [
      '/',
      '/transactions',
      '/accounts',
      '/more',
      '/settings',
    ]) {
      expect(offModuleRedirect(path), isNull, reason: path);
    }
  });
}
