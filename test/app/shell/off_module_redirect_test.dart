import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter_test/flutter_test.dart';

/// A module that's off (AppModules) has no pages: the router sends any
/// way in — deep link, notification link, openPage — somewhere safe.
void main() {
  bool Function(ShellTab) off(ShellTab t) =>
      (tab) => tab != t;
  bool allOn(ShellTab _) => true;
  bool allOff(ShellTab _) => false;

  test('redirect table', () {
    final cases = <(String, bool Function(ShellTab), String?)>[
      ('/projects/1', allOn, null),
      ('/pending', allOn, null),
      ('/projects', off(ShellTab.projects), '/more'),
      ('/projects/abc/members', off(ShellTab.projects), '/more'),
      ('/contacts/1', off(ShellTab.projects), null),
      ('/pending/new', off(ShellTab.pending), '/'),
      ('/notifications', off(ShellTab.notifications), '/'),
      ('/settings/notifications', off(ShellTab.notifications), '/'),
      ('/settings/profile', off(ShellTab.notifications), null),
      ('/dev/widgets', allOff, null),
      ('/auth/login', allOff, null),
    ];
    for (final (path, isOn, want) in cases) {
      expect(offModuleRedirect(path, isOn: isOn), want, reason: path);
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
