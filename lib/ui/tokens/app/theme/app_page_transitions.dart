import 'package:flutter/material.dart';

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static const _inner = PredictiveBackPageTransitionsBuilder();

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _inner.delegatedTransition;

  @override
  Duration get transitionDuration => _inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _CoveredRouteGate(
      child: _inner.buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      ),
    );
  }
}

class _CoveredRouteGate extends StatelessWidget {
  const _CoveredRouteGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final covered =
        _RouteCover.of(context) ||
        !(ModalRoute.isCurrentOf(context) ?? true) ||
        !TickerMode.valuesOf(context).enabled;
    return _RouteCover(
      covered: covered,
      child: PopScope(canPop: !covered, child: child),
    );
  }
}

class _RouteCover extends InheritedWidget {
  const _RouteCover({required this.covered, required super.child});

  final bool covered;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RouteCover>()?.covered ??
      false;

  @override
  bool updateShouldNotify(_RouteCover old) => covered != old.covered;
}
