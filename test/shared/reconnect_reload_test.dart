import 'package:chubi_pocket/ui/organisms/reconnect_reload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a page reloads once when the reconnect count moves', () {
    final cases = <(String, int?, int, bool)>[
      ('first look: nothing to compare', null, 0, false),
      ('first look after earlier outages', null, 3, false),
      ('offline / settling: count unchanged', 1, 1, false),
      ('back online: count +1', 1, 2, true),
      ('first outage ends', 0, 1, true),
    ];
    for (final (name, before, now, want) in cases) {
      expect(reloadsOnReconnect(before, now), want, reason: name);
    }
  });

  test('shown again: reopens only once the data is 5 minutes old', () {
    final t0 = DateTime(2026, 10, 24, 12);
    final cases = <(String, DateTime?, Duration, bool)>[
      ('never loaded', null, Duration.zero, true),
      ('just loaded', t0, const Duration(seconds: 30), false),
      ('a second short', t0, const Duration(minutes: 4, seconds: 59), false),
      ('exactly 5 min', t0, const Duration(minutes: 5), true),
      ('an hour later', t0, const Duration(hours: 1), true),
    ];
    for (final (name, loadedAt, after, want) in cases) {
      expect(reopensWhenShown(loadedAt, t0.add(after)), want, reason: name);
    }
  });
}
