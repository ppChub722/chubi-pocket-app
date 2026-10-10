import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter_test/flutter_test.dart';

/// A module that's off (AppModules) has no pages: the router sends any
/// way in — deep link, notification link, openPage — somewhere safe.
void main() {
  bool allOn(ShellTab _) => true;
  bool Function(ShellTab) off(ShellTab t) =>
      (tab) => tab != t;

  test('everything on — nothing redirects', () {
    for (final path in ['/', '/projects/1', '/pending', '/settings']) {
      expect(offModuleRedirect(path, isOn: allOn), isNull, reason: path);
    }
  });

  test('a เพิ่มเติม card that is off → the hub', () {
    final isOn = off(ShellTab.projects);
    expect(offModuleRedirect('/projects', isOn: isOn), '/more');
    expect(offModuleRedirect('/projects/abc/members', isOn: isOn), '/more');
    expect(offModuleRedirect('/contacts/1', isOn: isOn), isNull);
  });

  test('a top-bar module that is off → the dashboard', () {
    expect(offModuleRedirect('/pending/new', isOn: off(ShellTab.pending)), '/');
    expect(
      offModuleRedirect('/notifications', isOn: off(ShellTab.notifications)),
      '/',
    );
  });

  test('notification settings under ตั้งค่า belong to notifications', () {
    final isOn = off(ShellTab.notifications);
    expect(offModuleRedirect('/settings/notifications', isOn: isOn), '/');
    expect(offModuleRedirect('/settings/profile', isOn: isOn), isNull);
  });

  test('outside the shell is never blocked', () {
    bool none(ShellTab _) => false;
    expect(offModuleRedirect('/dev/widgets', isOn: none), isNull);
    expect(offModuleRedirect('/auth/login', isOn: none), isNull);
  });

  test('with the real switches, every core tab stays reachable', () {
    for (final path in ['/', '/transactions', '/accounts', '/more']) {
      expect(offModuleRedirect(path), isNull, reason: path);
    }
    expect(offModuleRedirect('/settings'), isNull);
  });
}
