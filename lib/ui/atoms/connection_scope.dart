import 'package:flutter/widgets.dart';

/// What the kit needs to know about the server connection (owner 2026-10-12,
/// offline mode). The app installs it once, at its root, from its connection
/// state; generic pieces read it:
///
/// - the templates show the full-page error + retry at once for a page with no
///   data (no skeleton wait) while [isOffline];
/// - save / submit / delete controls disable themselves while [isOffline] — the
///   banner says why — and typed input is never touched;
/// - when the connection comes back ([reconnects] goes up) every pull-to-refresh
///   page re-runs its load, as if pulled.
///
/// With no scope (a test, the hub) the app is online.
class ConnectionScope extends InheritedWidget {
  const ConnectionScope({
    required this.offline,
    required this.reconnects,
    required super.child,
    super.key,
  });

  final bool offline;

  /// Counts the times the connection came back.
  final int reconnects;

  /// The nearest scope's offline flag; subscribes the caller.
  static bool isOffline(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ConnectionScope>()?.offline ??
      false;

  /// The nearest scope's reconnect counter; subscribes the caller.
  static int reconnectsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ConnectionScope>()
          ?.reconnects ??
      0;

  @override
  bool updateShouldNotify(ConnectionScope old) =>
      offline != old.offline || reconnects != old.reconnects;
}
