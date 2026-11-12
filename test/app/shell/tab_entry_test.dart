import 'package:chubi_pocket/app/shell/nav_layout.dart';
import 'package:chubi_pocket/app/shell/tab_entry.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d = NavLayout.defaults;
  const card = Alignment(-0.5, 0.2);

  test('every switch slides in from the right, a back lands in place', () {
    final cases = <(String, ShellTab, ShellTab, Alignment?, bool, TabEntry)>[
      (
        'bottom → bottom',
        ShellTab.home,
        ShellTab.accounts,
        null,
        false,
        TabEntry.slide,
      ),
      (
        'the other way: the same',
        ShellTab.more,
        ShellTab.transactions,
        null,
        false,
        TabEntry.slide,
      ),
      (
        'top chip → bottom',
        ShellTab.pending,
        ShellTab.home,
        null,
        false,
        TabEntry.slide,
      ),
      (
        'bottom → top chip',
        ShellTab.home,
        ShellTab.notifications,
        null,
        false,
        TabEntry.slide,
      ),
      (
        'top → top',
        ShellTab.pending,
        ShellTab.settings,
        null,
        false,
        TabEntry.slide,
      ),
      (
        'More card → module: the origin no longer matters',
        ShellTab.more,
        ShellTab.debts,
        card,
        false,
        TabEntry.slide,
      ),
      (
        'notification → a bottom page',
        ShellTab.notifications,
        ShellTab.accounts,
        Alignment.topRight,
        false,
        TabEntry.slide,
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

  test('tapping the open tab plays its entry again, a back lands in place', () {
    expect(
      resolveTabEntry(
        from: ShellTab.accounts,
        to: ShellTab.accounts,
        layout: d,
        reopen: true,
      ),
      TabEntry.slide,
    );
    expect(
      resolveTabEntry(
        from: ShellTab.accounts,
        to: ShellTab.accounts,
        layout: d,
      ),
      TabEntry.none,
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

  test('a slide starts 80 % of the way and fades in, landing in place', () {
    expect(TabEntry.slide.offsetAt(0), const Offset(0.2, 0));
    expect(TabEntry.slide.offsetAt(1), Offset.zero);
    expect(TabEntry.slide.opacityAt(0), 0);
    expect(TabEntry.slide.opacityAt(1), 1);
    expect(TabEntry.fade.opacityAt(0), 0);
    expect(TabEntry.fade.offsetAt(0), Offset.zero);
    expect(TabEntry.none.opacityAt(0), 1);
    expect(TabEntry.none.offsetAt(0), Offset.zero);
    final m = TabEntry.slide.transformAt(0, const Size(400, 800));
    expect(m.getTranslation().x, 80);
    expect(m.getTranslation().y, 0);
  });
}
