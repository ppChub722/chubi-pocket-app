import 'package:chubi_pocket/app/shell/nav_layout.dart';
import 'package:chubi_pocket/app/shell/tab_entry.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d = NavLayout.defaults;
  const card = Alignment(-0.5, 0.2);

  test('how a tab arrives, per where it comes from', () {
    final cases = <(String, ShellTab, ShellTab, Alignment?, bool, TabEntry)>[
      (
        'bottom → bottom to the right: from the right',
        ShellTab.home,
        ShellTab.accounts,
        null,
        false,
        const TabEntry.side(1),
      ),
      (
        'bottom → bottom to the left: from the left',
        ShellTab.more,
        ShellTab.transactions,
        null,
        false,
        const TabEntry.side(-1),
      ),
      (
        'top chip → bottom: up from below',
        ShellTab.pending,
        ShellTab.home,
        null,
        false,
        TabEntry.up,
      ),
      (
        'More-only page → bottom: up from below',
        ShellTab.budgets,
        ShellTab.transactions,
        null,
        false,
        TabEntry.up,
      ),
      (
        'bottom → top chip: down from above',
        ShellTab.home,
        ShellTab.notifications,
        null,
        false,
        TabEntry.down,
      ),
      (
        'top → top: down from above',
        ShellTab.pending,
        ShellTab.settings,
        null,
        false,
        TabEntry.down,
      ),
      (
        'More card → module: grows out of the card',
        ShellTab.more,
        ShellTab.debts,
        card,
        false,
        const TabEntry.expand(card),
      ),
      (
        'notification → a bottom page: grows out of the bell',
        ShellTab.notifications,
        ShellTab.accounts,
        Alignment.topRight,
        false,
        const TabEntry.expand(Alignment.topRight),
      ),
      (
        'no known origin (a link) → module: grows out of the centre',
        ShellTab.home,
        ShellTab.projects,
        null,
        false,
        const TabEntry.expand(),
      ),
      (
        'a back: already in place',
        ShellTab.budgets,
        ShellTab.more,
        card,
        true,
        TabEntry.none,
      ),
    ];
    for (final (name, from, to, origin, back, want) in cases) {
      expect(
        resolveTabEntry(
          from: from,
          to: to,
          layout: d,
          origin: origin,
          back: back,
        ),
        want,
        reason: name,
      );
    }
    expect(
      resolveTabEntry(
        from: ShellTab.home,
        to: ShellTab.accounts,
        layout: d,
        reducedMotion: true,
      ),
      TabEntry.fade,
      reason: 'reduced motion: a fade only',
    );
  });

  test('the bars follow the layout: an off item is skipped for the side', () {
    final off = d.withOff({ShellTab.transactions});
    expect(
      resolveTabEntry(from: ShellTab.home, to: ShellTab.accounts, layout: off),
      const TabEntry.side(1),
    );
  });

  test('origin → alignment, the centre when unknown', () {
    const size = Size(400, 800);
    expect(originAlignment(null, size), Alignment.center);
    expect(
      originAlignment(const Rect.fromLTWH(10, 10, 20, 20), Size.zero),
      Alignment.center,
    );
    expect(
      originAlignment(const Rect.fromLTWH(0, 0, 200, 400), size),
      const Alignment(-0.5, -0.5),
    );
    expect(
      originAlignment(const Rect.fromLTWH(380, -20, 40, 40), size),
      const Alignment(1, -1),
      reason: 'clamped inside the page',
    );
  });

  test('small shifts and a 0.8 → 1 grow, all landing in place', () {
    for (final e in [
      const TabEntry.side(1),
      TabEntry.up,
      TabEntry.down,
      const TabEntry.expand(card),
    ]) {
      expect(e.offsetAt(1), Offset.zero, reason: '$e');
      expect(e.scaleAt(1), 1, reason: '$e');
      expect(e.opacityAt(0), 0, reason: '$e');
    }
    expect(const TabEntry.side(-1).offsetAt(0), const Offset(-0.06, 0));
    expect(TabEntry.up.offsetAt(0), const Offset(0, 0.06));
    expect(TabEntry.down.offsetAt(0), const Offset(0, -0.06));
    expect(const TabEntry.expand(card).scaleAt(0), 0.8);
    expect(TabEntry.none.opacityAt(0), 1);
  });
}
