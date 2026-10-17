import 'package:flutter/widgets.dart';

class ConnectionScope extends InheritedWidget {
  const ConnectionScope({
    required this.offline,
    required this.reconnects,
    required super.child,
    super.key,
  });

  final bool offline;

  final int reconnects;

  static bool isOffline(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ConnectionScope>()?.offline ??
      false;

  static int reconnectsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ConnectionScope>()
          ?.reconnects ??
      0;

  @override
  bool updateShouldNotify(ConnectionScope old) =>
      offline != old.offline || reconnects != old.reconnects;
}
