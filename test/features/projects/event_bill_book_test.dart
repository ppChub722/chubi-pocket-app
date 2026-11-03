import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 0.4.1-2 X1: the sheet opens with "คืนแล้ว" as saved, else an edit sends
  // paid_back:false and the BE removes the payback.
  test('a bill row: each split keeps its paid_back (BoardSplit)', () {
    final rows = ProjectTransaction.flatten({
      'id': 'b1',
      'project_id': 'p1',
      'type': 'expense',
      'amount': 300,
      'date': '2026-10-27',
      'children': [
        {'id': 's1', 'amount': 100, 'marks': <Object>[], 'paid_back': true},
        {'id': 's2', 'amount': 100, 'marks': <Object>[], 'paid_back': false},
        {'id': 's3', 'amount': 100, 'marks': <Object>[]},
      ],
    });
    expect([for (final r in rows) r.paidBack], [false, true, false, false]);
  });
}
