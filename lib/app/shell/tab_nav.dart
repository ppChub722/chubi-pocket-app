import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_modules.dart';

/// The shell's tabs, in branch order — app_router.dart builds one
/// [StatefulShellBranch] per value, in this order (owner 2026-10-09: every
/// page group is its own tab, so nothing stacks onto another tab).
enum ShellTab {
  home,
  transactions,
  accounts,
  more,
  // Opened from the top bar's ⏳ / 🔔 / 👤 chips.
  pending,
  notifications,
  settings,
  // The เพิ่มเติม hub's cards.
  projects,
  contacts,
  budgets,
  scheduled,
  savingGoals,
  debts,
  categories,
  tags;

  /// Switched on in [AppModules] — the core tabs always are.
  bool get enabled => switch (this) {
    home || transactions || accounts || more || settings => true,
    pending => AppModules.pending,
    notifications => AppModules.notifications,
    projects => AppModules.projects,
    contacts => AppModules.contacts,
    budgets => AppModules.budgets,
    scheduled => AppModules.scheduled,
    savingGoals => AppModules.savingGoals,
    debts => AppModules.debts,
    categories => AppModules.categories,
    tags => AppModules.tags,
  };

  /// The on-screen row this tab sits in.
  ShellRow get row => ShellRow.values.firstWhere((r) => r.all.contains(this));

  /// One of the four bottom-nav slots.
  bool get inNav => row == ShellRow.nav;

  /// Opened from the เพิ่มเติม hub: back at its root → the hub.
  bool get inMore => row.inMore;

  /// The tab [step] places along this one's row, counting only tabs that
  /// are switched on — null past either end.
  ShellTab? beside(int step) {
    final tabs = row.tabs;
    final i = tabs.indexOf(this);
    if (i < 0) return null;
    final j = i + step;
    return j < 0 || j >= tabs.length ? null : tabs[j];
  }

  /// Which side [to] lies on: 1 right, -1 left, 0 another row (no side).
  int sideOf(ShellTab to) =>
      to.row != row ? 0 : (row.all.indexOf(to) - row.all.indexOf(this)).sign;
}

/// Tabs that sit side by side on screen, in on-screen order (owner
/// 2026-10-10). Swipe moves along a row, and a switch within one slides in
/// from the side the new tab lies on. The เพิ่มเติม rows are the hub's
/// sections too — add a tab here and its card, chip and swipe place follow.
enum ShellRow {
  /// The bottom nav.
  nav([ShellTab.home, ShellTab.transactions, ShellTab.accounts, ShellTab.more]),

  /// The top bar's ⏳ / 🔔 / 👤 chips.
  top([ShellTab.pending, ShellTab.notifications, ShellTab.settings]),

  // เพิ่มเติม hub sections, top to bottom.
  library([ShellTab.categories, ShellTab.tags]),
  people([ShellTab.contacts, ShellTab.projects, ShellTab.debts]),
  planning([ShellTab.budgets, ShellTab.savingGoals, ShellTab.scheduled]);

  const ShellRow(this.all);

  /// Every tab of the row, switched on or not.
  final List<ShellTab> all;

  /// The row's tabs that are switched on — what's on screen.
  List<ShellTab> get tabs => [
    for (final t in all)
      if (t.enabled) t,
  ];

  /// A section of the เพิ่มเติม hub.
  bool get inMore => index >= library.index;
}

/// Opens [location] where it lives — returned as a closure so callers can
/// capture it before an `await` (the context may be gone after).
///
/// A page of the current tab is pushed onto it. A page of another tab
/// switches to that tab instead (`go`: its stack becomes the page's route
/// chain), so pages never pile onto a tab they don't belong to. Back from
/// there walks the shell's tab history to where the user came from.
///
/// Works from anywhere — a sheet or dialog above the shell too: the tabs
/// are compared from the router's state, not the widget tree.
void Function(String location, {Object? extra}) pageOpener(
  BuildContext context,
) {
  final router = GoRouter.of(context);
  return (location, {extra}) {
    final here = _branchKey(router.routerDelegate.currentConfiguration);
    final there = _branchKey(
      router.configuration.findMatch(Uri.parse(location), extra: extra),
    );
    if (here == null || there == null || here == there) {
      router.push(location, extra: extra);
    } else {
      router.go(location, extra: extra);
    }
  };
}

/// [pageOpener] for a single call.
void openPage(BuildContext context, String location, {Object? extra}) =>
    pageOpener(context)(location, extra: extra);

/// The navigator of the shell branch [matches] lands in, or null outside
/// the shell (`/dev`, `/auth`).
GlobalKey<NavigatorState>? _branchKey(RouteMatchList matches) {
  for (final m in matches.matches) {
    if (m is ShellRouteMatch && m.route is StatefulShellRoute) {
      return m.navigatorKey;
    }
  }
  return null;
}

/// The shell's back for a tab's root page — the top bar's ← calls it when
/// there's nothing left to pop in the tab (see `MainShell`).
class ShellBackScope extends InheritedWidget {
  const ShellBackScope({required this.onBack, required super.child, super.key});

  final VoidCallback onBack;

  static VoidCallback? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellBackScope>()?.onBack;

  @override
  bool updateShouldNotify(ShellBackScope old) => onBack != old.onBack;
}
