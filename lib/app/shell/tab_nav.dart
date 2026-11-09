import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../ui/domain/tokens/app_modules.dart';
import 'nav_layout.dart';
import 'tab_entry.dart';
import '../../ui/app_aliases.dart';

enum ShellTab {
  home,
  transactions,
  accounts,
  more,
  pending,
  notifications,
  settings,
  projects,
  contacts,
  budgets,
  recurring,
  savingGoals,
  debts,
  categories,
  tags;

  bool get enabled => switch (this) {
    home || transactions || accounts || more || settings => true,
    pending => AppModules.pending,
    notifications => AppModules.notifications,
    projects => AppModules.projects,
    contacts => AppModules.contacts,
    budgets => AppModules.budgets,
    recurring => AppModules.recurring,
    savingGoals => AppModules.savingGoals,
    debts => AppModules.debts,
    categories => AppModules.categories,
    tags => AppModules.tags,
  };

  static const _segments = {
    '': home,
    'browse': home,
    'transactions': transactions,
    'accounts': accounts,
    'more': more,
    'pending': pending,
    'notifications': notifications,
    'settings': settings,
    'archived': settings,
    'projects': projects,
    'contacts': contacts,
    'budgets': budgets,
    'recurring': recurring,
    'saving-goals': savingGoals,
    'personal-debts': debts,
    'categories': categories,
    'tags': tags,
  };

  /// The tab's first page.
  String get path =>
      '/${_segments.entries.firstWhere((e) => e.value == this).key}';

  static ShellTab? ofPath(String location) {
    final path = Uri.parse(location).path;
    final segments = path.split('/').where((s) => s.isNotEmpty);
    return _segments[segments.isEmpty ? '' : segments.first];
  }

  static ShellTab? moduleOfPath(String location) {
    final path = Uri.parse(location).path;
    if (path == '/settings/notifications') return notifications;
    return ofPath(path);
  }

}

String? offModuleRedirect(String location, {NavLayout? layout}) {
  final nav = layout ?? NavLayout.defaults;
  final tab = ShellTab.moduleOfPath(location);
  if (tab == null || nav.isOn(tab)) return null;
  return nav.isMoreOnly(tab) ? '/more' : '/';
}

/// The one way the shell switches tabs (nav bar, top-bar chips, swipes, back
/// on a tab root). A link into a page of another tab goes through
/// [openPage] instead.
///
/// Entering a tab starts it over (owner 2026-11-05): the pages it was left on
/// leave unseen and its first page arrives with the tab's entry. Tapping the
/// tab already open does the same, playing the entry again (nothing happens
/// when it is already on its first page). A [back] returns to the tab as it
/// was left.
void goTab(
  ShellTab to, {
  required int from,
  required void Function(int index, {bool initialLocation}) goBranch,
  bool Function(int index)? canPop,
  bool back = false,
}) {
  if (back) {
    goBranch(to.index, initialLocation: false);
    return;
  }
  final reopen = to.index == from;
  final stacked = canPop?.call(to.index) ?? true;
  if (reopen && !stacked) return;
  if (stacked) AppPageTransitionsBuilder.popNextWithoutAnimation();
  goBranch(to.index, initialLocation: true);
  if (reopen) ShellReopen.request();
}

/// Whether the tab [index] of [route] has a page above its first one.
bool Function(int index) branchCanPop(StatefulShellRoute route) =>
    (index) =>
        route.branches[index].navigatorKey.currentState?.canPop() ?? true;

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
      AppPageTransitionsBuilder.landNextWithoutPush();
      router.go(location, extra: extra);
    }
  };
}

void openPage(BuildContext context, String location, {Object? extra}) =>
    pageOpener(context)(location, extra: extra);

GlobalKey<NavigatorState>? _branchKey(RouteMatchList matches) {
  for (final m in matches.matches) {
    if (m is ShellRouteMatch && m.route is StatefulShellRoute) {
      return m.navigatorKey;
    }
  }
  return null;
}

class ShellBackScope extends InheritedWidget {
  const ShellBackScope({required this.onBack, required super.child, super.key});

  final VoidCallback onBack;

  static VoidCallback? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellBackScope>()?.onBack;

  @override
  bool updateShouldNotify(ShellBackScope old) => onBack != old.onBack;
}

/// The app's [PageExitScope.onLeave]: pop the page — or, opened alone in its
/// tab with nothing to pop, let the shell's back take over (previous tab, the
/// เพิ่มเติม hub, or the dashboard).
void leaveShellPage(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    ShellBackScope.maybeOf(context)?.call();
  }
}

abstract interface class ShellSwipeHandler {
  bool canSwipe(int dir);

  void onSwipe(int dir);
}

class ShellSwipeScope extends InheritedWidget {
  const ShellSwipeScope({
    required this.handlers,
    required super.child,
    super.key,
  });

  final Map<ShellTab, ShellSwipeHandler> handlers;

  static Map<ShellTab, ShellSwipeHandler>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellSwipeScope>()?.handlers;

  @override
  bool updateShouldNotify(ShellSwipeScope old) => handlers != old.handlers;
}
