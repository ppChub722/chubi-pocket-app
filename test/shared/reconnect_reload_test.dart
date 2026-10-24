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
}
