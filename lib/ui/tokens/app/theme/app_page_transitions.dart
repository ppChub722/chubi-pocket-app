import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static const _inner = PredictiveBackPageTransitionsBuilder();

  static bool _landing = false;
  static Timer? _landingEnd;
  static final _landed = Expando<bool>();

  /// A cross-tab open: the pages it builds arrive under the tab switch's own
  /// animation, so they skip their push (popping them still animates).
  static void landNextWithoutPush() {
    _landing = true;
    _landingEnd?.cancel();
    _landingEnd = Timer(const Duration(milliseconds: 500), _endLanding);
  }

  static void _endLanding() {
    _landing = false;
    _landingEnd?.cancel();
    _landingEnd = null;
  }

  bool _landsWithoutPush(PageRoute<dynamic> route) {
    final known = _landed[route];
    if (known != null) return known;
    _landed[route] = _landing;
    if (_landing) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _endLanding());
    }
    return _landing;
  }

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
    final landed =
        _landsWithoutPush(route) && animation.status == AnimationStatus.forward;
    return _CoveredRouteGate(
      child: _inner.buildTransitions(
        route,
        context,
        landed ? kAlwaysCompleteAnimation : animation,
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
