import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../ui/tokens/app/app_modules.dart';
import '../../ui/tokens/app/theme/app_page_transitions.dart';
import 'nav_layout.dart';

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

  /// Left for another tab, this tab comes back at its first page instead of
  /// the page it was left on (owner 2026-10-28: the profile / settings tab).
  bool get resetsOnReturn => this == settings;

  /// Whether switching [from] a tab to this one lands on this tab's first
  /// page: tapping the tab already open pops it home, and a tab that
  /// [resetsOnReturn] always starts there. Other tabs keep their stack.
  bool opensAtRootFrom(ShellTab from) => from == this || resetsOnReturn;
}

String? offModuleRedirect(String location, {NavLayout? layout}) {
  final nav = layout ?? NavLayout.defaults;
  final tab = ShellTab.moduleOfPath(location);
  if (tab == null || nav.isOn(tab)) return null;
  return nav.isMoreOnly(tab) ? '/more' : '/';
}

/// The one way the shell switches tabs (nav bar, top-bar chips, swipes, back
/// on a tab root); see [ShellTab.opensAtRootFrom]. A link into a page of
/// another tab goes through [openPage] instead.
void goTab(
  ShellTab to, {
  required int from,
  required void Function(int index, {bool initialLocation}) goBranch,
}) {
  final root = to.opensAtRootFrom(ShellTab.values[from]);
  // Back to a tab that starts over: the page it was left on leaves unseen,
  // the tab's home arrives with the tab's own entry only.
  if (goTabDropsPages(to, from: from)) {
    AppPageTransitionsBuilder.popNextWithoutAnimation();
  }
  goBranch(to.index, initialLocation: root);
}

/// Whether switching [from] → [to] drops [to]'s pages without a back slide:
/// only a tab that [ShellTab.resetsOnReturn], entered from another tab
/// (tapping the open tab pops home with the usual slide).
bool goTabDropsPages(ShellTab to, {required int from}) =>
    to.resetsOnReturn && to.index != from;

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
