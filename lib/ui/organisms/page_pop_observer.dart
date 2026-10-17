import 'package:flutter/widgets.dart';

class PagePopObserver extends NavigatorObserver {
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
