import 'package:flutter/widgets.dart';

/// How a page leaves itself (create cancel, back in view mode) — the host
/// app's navigation, injected so the kit never depends on a router (ppForge:
/// generic pieces import no go_router). The app installs one at its root;
/// without one a page pops its own [Navigator] when it can.
class PageExitScope extends InheritedWidget {
  const PageExitScope({required this.onLeave, required super.child, super.key});

  /// Called with the leaving page's context.
  final void Function(BuildContext context) onLeave;

  /// Leaves the page [context] belongs to.
  static void leave(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<PageExitScope>();
    if (scope != null) {
      scope.onLeave(context);
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  bool updateShouldNotify(PageExitScope old) => onLeave != old.onLeave;
}
