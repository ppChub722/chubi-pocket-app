import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drafts made from a recurring / upcoming item (owner 2026-10-13): the
/// source and its ref parse, and the chip reads "Netflix · 3/12".
void main() {
  Map<String, dynamic> row(String source, Object? ref) => {
    'id': 'p1',
    'source': source,
    'kind': 'create',
    'draft': {'type': 'expense', 'amount': 419},
    'created_at': '2026-10-13T08:00:00Z',
    'source_ref': ref,
  };

  test('a recurring item: 🔁 Netflix · 3/12', () {
    final p = PendingTransaction.fromJson(
      row('recurring', {
        'item_id': 'i3',
        'recurring': {'id': 'r1', 'name': 'Netflix', 'icon_code': null},
        'seq': 3,
        'total': 12,
      }),
    );
    expect(p.source, PendingSource.recurring);
    expect(p.source.isManual, isFalse);
    expect(p.recurringRef?.recurringId, 'r1');
    expect(p.recurringRef?.label('Recurring'), 'Netflix · 3/12');
  });

  test('a one-off upcoming item: no recurring, the fallback name', () {
    final p = PendingTransaction.fromJson(
      row('upcoming', {
        'item_id': 'i9',
        'recurring': null,
        'seq': null,
        'total': null,
      }),
    );
    expect(p.source, PendingSource.upcoming);
    expect(p.recurringRef?.recurringId, isNull);
    expect(p.recurringRef?.label('Upcoming'), 'Upcoming');
  });

  test('another source never reads its ref as a recurring item', () {
    final p = PendingTransaction.fromJson(row('manual', {'item_id': 'x'}));
    expect(p.recurringRef, isNull);
  });
}
