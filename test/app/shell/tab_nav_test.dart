import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every tab sits in exactly one row', () {
    for (final tab in ShellTab.values) {
      final rows = ShellRow.values.where((r) => r.all.contains(tab));
      expect(rows, hasLength(1), reason: '$tab');
    }
  });

  test('rows hold the tabs in on-screen order', () {
    expect(ShellRow.top.all, [
      ShellTab.pending,
      ShellTab.notifications,
      ShellTab.settings,
    ]);
    expect(ShellRow.planning.all, [
      ShellTab.budgets,
      ShellTab.savingGoals,
      ShellTab.recurring,
    ]);
    expect(ShellRow.people.all, [ShellTab.debts, ShellTab.projects]);
    expect(ShellRow.library.all, [
      ShellTab.categories,
      ShellTab.tags,
      ShellTab.contacts,
    ]);
  });

  test('beside walks the row and stops at its ends', () {
    expect(ShellTab.home.beside(1), ShellTab.transactions);
    expect(ShellTab.home.beside(-1), isNull);
    expect(ShellTab.more.beside(1), isNull); // not into ⏳
    expect(ShellTab.notifications.beside(1), ShellTab.settings);
    expect(ShellTab.contacts.beside(1), isNull); // last of the hub
    expect(ShellTab.recurring.beside(1), isNull); // not into debts
    expect(ShellTab.projects.beside(-1), ShellTab.debts);
  });

  test('sideOf: in-row by position, across rows none', () {
    expect(ShellTab.transactions.sideOf(ShellTab.more), 1);
    expect(ShellTab.projects.sideOf(ShellTab.debts), -1);
    expect(ShellTab.more.sideOf(ShellTab.projects), 0);
    expect(ShellTab.home.sideOf(ShellTab.pending), 0);
  });

  test('every on-screen row tab is switched on by default', () {
    for (final row in ShellRow.values) {
      expect(row.tabs, row.all, reason: '$row');
    }
  });
}
