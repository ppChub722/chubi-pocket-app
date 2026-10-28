import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../ui/tokens/app/app_modules.dart';
import '../../ui/tokens/app/theme/app_page_transitions.dart';

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

  ShellRow get row => ShellRow.values.firstWhere((r) => r.all.contains(this));

  bool get inNav => row == ShellRow.nav;

  bool get inMore => row.inMore;

  ShellTab? beside(int step) {
    final tabs = row.tabs;
    final i = tabs.indexOf(this);
    if (i < 0) return null;
    final j = i + step;
    return j < 0 || j >= tabs.length ? null : tabs[j];
  }

  int sideOf(ShellTab to) =>
      to.row != row ? 0 : (row.all.indexOf(to) - row.all.indexOf(this)).sign;
}

enum ShellRow {
  nav([ShellTab.home, ShellTab.transactions, ShellTab.accounts, ShellTab.more]),

  top([ShellTab.pending, ShellTab.notifications, ShellTab.settings]),

  planning([ShellTab.budgets, ShellTab.savingGoals, ShellTab.recurring]),

  people([ShellTab.debts, ShellTab.projects]),

  library([ShellTab.categories, ShellTab.tags, ShellTab.contacts]);

  const ShellRow(this.all);

  final List<ShellTab> all;

  List<ShellTab> get tabs => [
    for (final t in all)
      if (t.enabled) t,
  ];

  bool get inMore => index >= planning.index;
}

String? offModuleRedirect(String location, {bool Function(ShellTab)? isOn}) {
  final tab = ShellTab.moduleOfPath(location);
  if (tab == null || (isOn ?? (t) => t.enabled)(tab)) return null;
  return tab.inMore ? '/more' : '/';
}

/// The one way the shell switches tabs (nav bar, top-bar chips, swipes, back
/// on a tab root); see [ShellTab.opensAtRootFrom]. A link into a page of
/// another tab goes through [openPage] instead.
void goTab(
  ShellTab to, {
  required int from,
  required void Function(int index, {bool initialLocation}) goBranch,
}) => goBranch(
  to.index,
  initialLocation: to.opensAtRootFrom(ShellTab.values[from]),
);

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
