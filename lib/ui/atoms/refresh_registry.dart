import 'package:flutter/widgets.dart';

/// Every `PullToRefresh` on screen registers its refresh here, so the app can
/// run "pull-to-refresh" on the visible screen or sheet without a gesture
/// (coming back to the app).
class RefreshRegistry {
  final _entries = <Object, _Entry>{};

  void register(
    Object owner, {
    required ModalRoute<dynamic>? route,
    required bool Function() isActive,
    required Future<void> Function() run,
  }) {
    _entries[owner] = _Entry(route, isActive, run);
  }

  void unregister(Object owner) => _entries.remove(owner);

  /// Runs the refresh of everything visible on the top route (the sheet when a
  /// sheet is open, else the page). Completes false when nothing was visible.
  Future<bool> refreshCurrent() async {
    final live = [
      for (final e in _entries.values)
        if ((e.route?.isCurrent ?? true) && e.isActive()) e,
    ];
    if (live.isEmpty) return false;
    await Future.wait([
      for (final e in live)
        () async {
          try {
            await e.run();
          } catch (_) {
            // The screen shows its own error.
          }
        }(),
    ]);
    return true;
  }
}

class _Entry {
  _Entry(this.route, this.isActive, this.run);

  final ModalRoute<dynamic>? route;
  final bool Function() isActive;
  final Future<void> Function() run;
}

class RefreshScope extends InheritedWidget {
  const RefreshScope({required this.registry, required super.child, super.key});

  final RefreshRegistry registry;

  static RefreshRegistry? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RefreshScope>()?.registry;

  @override
  bool updateShouldNotify(RefreshScope old) => registry != old.registry;
}
