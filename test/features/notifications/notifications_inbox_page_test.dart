import 'package:chubi_pocket/features/notifications/presentation/notification_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extendedEnd: the same length again, from the payload only', () {
    expect(
      extendedEnd({
        'end': {'kind': 'count', 'count': 6},
      }),
      {'kind': 'count', 'count': 12},
    );
    // 2026-01-01 → 2026-07-01 is 181 days: the new end adds the same span.
    expect(
      extendedEnd({
        'start_date': '2026-01-01',
        'end': {'kind': 'date', 'date': '2026-07-01'},
      }),
      {'kind': 'date', 'date': '2026-12-29'},
    );
    // No start in the payload: +1 year.
    expect(
      extendedEnd({
        'end': {'kind': 'date', 'date': '2026-07-01'},
      }),
      {'kind': 'date', 'date': '2027-07-01'},
    );
    expect(
      extendedEnd({
        'end': {'kind': 'none'},
      }),
      isNull,
    );
    expect(extendedEnd({'name': 'x'}), isNull);
  });
}
