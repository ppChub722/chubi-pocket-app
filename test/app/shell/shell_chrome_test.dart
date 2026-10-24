import 'package:chubi_pocket/app/shell/shell_chrome.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell nav must NEVER stay hidden when no editing bar is on screen
/// (owner 2026-10-12: back pressed quickly left it hidden; 2026-10-24: a page
/// left in another tab kept it hidden). It is read from the claims' state on
/// every refresh, never remembered.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hidden exactly while some claim is on screen, from state', () {
    final c = ShellChromeController();
    var notified = 0;
    c.addListener(() => notified++);
    var aOn = false;
    var bOn = false;
    final a = c.claim(() => aOn);
    c.claim(() => bOn);

    final steps = <(String, bool, bool, bool)>[
      ('no bar on screen', false, false, false),
      ('a editing on screen', true, false, true),
      ('both', true, true, true),
      ('a left, b still on screen', false, true, true),
      ('b covered / other tab: answers no', false, false, false),
    ];
    for (final (name, aState, bState, want) in steps) {
      aOn = aState;
      bOn = bState;
      c.recompute();
      expect(c.hidden, want, reason: name);
    }
    expect(notified, 2, reason: 'only real changes notify');

    aOn = true;
    a.release();
    c.recompute();
    expect(
      c.hidden,
      isFalse,
      reason: 'a released claim never hides, whatever it would answer',
    );
  });
}
