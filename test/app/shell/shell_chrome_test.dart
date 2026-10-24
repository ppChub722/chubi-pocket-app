import 'package:chubi_pocket/app/shell/shell_chrome.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell nav must NEVER stay hidden on a tab root (owner 2026-10-12: back
/// pressed quickly from an edit page left the bottom bar hidden).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hidden while ANY owner holds it', () {
    final c = ShellChromeController();
    var notified = 0;
    c.addListener(() => notified++);
    final a = Object();
    final b = Object();
    c.hide(owner: a);
    c.hide(owner: b);
    expect(c.hidden, isTrue);
    expect(notified, 1, reason: 'only the first hide changes anything');
    c.show(owner: a);
    expect(c.hidden, isTrue, reason: 'b still holds it');
    expect(notified, 1);
    c.show(owner: b);
    expect(c.hidden, isFalse);
    expect(notified, 2);
    c.show(owner: b);
    expect(c.hidden, isFalse, reason: 'releasing twice is harmless');
    expect(notified, 2);
  });
}
