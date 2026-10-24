import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every tab sits in exactly one row, switched on by default', () {
    for (final tab in ShellTab.values) {
      final rows = ShellRow.values.where((r) => r.all.contains(tab));
      expect(rows, hasLength(1), reason: '$tab');
    }
    for (final row in ShellRow.values) {
      expect(row.tabs, row.all, reason: '$row');
    }
  });
}
