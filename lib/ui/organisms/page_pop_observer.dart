import 'package:flutter/widgets.dart';

/// Counts the PAGES popped (not sheets, dialogs or menus) — the signal behind
/// "refresh on show": a page that was covered by another page re-runs its one
/// page call when that page is popped (`PullToRefresh`). Add one to the
/// router and to every shell branch's observers.
class PagePopObserver extends NavigatorObserver {
  /// Pages popped so far, app-wide.
  static int generation = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) generation++;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) generation++;
  }
}
