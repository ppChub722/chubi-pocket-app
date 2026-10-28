import 'package:flutter/widgets.dart';

import 'tab_nav.dart';

/// A group of cards on the เพิ่มเติม page (its title and tint live there).
enum NavGroupId { planning, people, library }

@immutable
class NavGroup {
  const NavGroup(this.id, this.items);

  final NavGroupId id;
  final List<ShellTab> items;

  @override
  bool operator ==(Object other) =>
      other is NavGroup && other.id == id && _sameList(other.items, items);

  @override
  int get hashCode => Object.hash(id, Object.hashAll(items));
}

/// The two bars a swipe can switch along.
enum NavBar { bottom, top }

/// Where every page group sits: the bottom bar, the top-right chips, the
/// เพิ่มเติม groups, and which modules are off. The shell reads only this
/// (bars, chips, More page, swipe targets, entry animations), so a per-user
/// layout later (0.4.3) only has to hand the shell another one.
@immutable
class NavLayout {
  const NavLayout({
    required this.bottom,
    required this.top,
    required this.more,
    this.off = const {},
  });

  /// The bottom bar's items, left to right (the + sits in the middle).
  final List<ShellTab> bottom;

  /// The top-right chips, left to right.
  final List<ShellTab> top;

  /// The เพิ่มเติม page's module groups, top to bottom.
  final List<NavGroup> more;

  /// Modules switched off: gone from every place the shell controls.
  final Set<ShellTab> off;

  /// Today's layout (the compile-time module switches decide [off]).
  static final NavLayout defaults = NavLayout(
    bottom: const [
      ShellTab.home,
      ShellTab.transactions,
      ShellTab.accounts,
      ShellTab.more,
    ],
    top: const [ShellTab.pending, ShellTab.notifications, ShellTab.settings],
    more: const [
      NavGroup(NavGroupId.planning, [
        ShellTab.budgets,
        ShellTab.savingGoals,
        ShellTab.recurring,
      ]),
      NavGroup(NavGroupId.people, [ShellTab.debts, ShellTab.projects]),
      NavGroup(NavGroupId.library, [
        ShellTab.categories,
        ShellTab.tags,
        ShellTab.contacts,
      ]),
    ],
    off: {
      for (final t in ShellTab.values)
        if (!t.enabled) t,
    },
  );

  bool isOn(ShellTab tab) => !off.contains(tab);

  NavLayout withOff(Set<ShellTab> off) =>
      NavLayout(bottom: bottom, top: top, more: more, off: off);

  /// [bar]'s items that are on, in order.
  List<ShellTab> itemsOf(NavBar bar) => [
    for (final t in bar == NavBar.bottom ? bottom : top)
      if (isOn(t)) t,
  ];

  List<ShellTab> get bottomItems => itemsOf(NavBar.bottom);

  List<ShellTab> get topItems => itemsOf(NavBar.top);

  /// The เพิ่มเติม groups with only the modules that are on; empty groups
  /// are dropped.
  List<NavGroup> get moreGroups => [
    for (final g in more)
      if (g.items.any(isOn))
        NavGroup(g.id, [
          for (final t in g.items)
            if (isOn(t)) t,
        ]),
  ];

  /// The bar [tab] sits in (and highlights it), or null for a page only the
  /// เพิ่มเติม page opens.
  NavBar? barOf(ShellTab tab) => bottomItems.contains(tab)
      ? NavBar.bottom
      : topItems.contains(tab)
      ? NavBar.top
      : null;

  /// A page only the เพิ่มเติม page opens (no bar highlights it).
  bool isMoreOnly(ShellTab tab) =>
      barOf(tab) == null && more.any((g) => g.items.contains(tab));

  /// The tab a swipe along [bar] lands on, [step] items from [current]; null
  /// when [current] isn't in that bar or there's nothing that way (the bar
  /// still follows the finger, then eases back).
  ShellTab? swipeTarget(NavBar bar, ShellTab current, int step) {
    final items = itemsOf(bar);
    final i = items.indexOf(current);
    if (i < 0 || step == 0) return null;
    final j = i + step;
    return j < 0 || j >= items.length ? null : items[j];
  }

  @override
  bool operator ==(Object other) =>
      other is NavLayout &&
      _sameList(other.bottom, bottom) &&
      _sameList(other.top, top) &&
      _sameList(other.more, more) &&
      other.off.length == off.length &&
      other.off.containsAll(off);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(bottom),
    Object.hashAll(top),
    Object.hashAll(more),
    Object.hashAllUnordered(off),
  );
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Hands the shell's [NavLayout] down to the bars, the chips, the More page
/// and settings.
class NavLayoutScope extends InheritedWidget {
  const NavLayoutScope({required this.layout, required super.child, super.key});

  final NavLayout layout;

  /// The layout (rebuilds on change); [NavLayout.defaults] outside a shell.
  static NavLayout of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavLayoutScope>()?.layout ??
      NavLayout.defaults;

  /// The layout without a rebuild dependency (callbacks, didUpdateWidget).
  static NavLayout read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<NavLayoutScope>()?.layout ??
      NavLayout.defaults;

  @override
  bool updateShouldNotify(NavLayoutScope old) => layout != old.layout;
}
