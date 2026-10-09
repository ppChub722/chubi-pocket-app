import 'package:flutter/material.dart';

/// Android's predictive-back page transition, made safe for the shell's
/// nested navigators.
///
/// Flutter's [PredictiveBackPageTransitionsBuilder] lets a page claim the
/// system back gesture whenever it's the top route of *its own* navigator.
/// In the shell that's wrong in two places:
/// - a sheet / dialog / overlay page on the root navigator covers the
///   branch, yet the branch's top page still claims the gesture — it pops
///   itself under the sheet and the sheet never closes;
/// - inactive tabs stay mounted, so a pushed page in a hidden tab claims
///   it too and silently disappears.
///
/// Here every page gets a [PopScope] that vetoes pops while the page is
/// covered (an ancestor route isn't current) or hidden (tickers off — the
/// shell disables them for inactive tabs). A vetoed page can't start a
/// predictive gesture, so back falls through to the router, which picks
/// the right navigator. Visible pages keep the predictive animation.
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

/// Publishes whether this page is covered, so pages in nested navigators
/// (inside the shell's page) inherit it, and vetoes pops while it is.
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
