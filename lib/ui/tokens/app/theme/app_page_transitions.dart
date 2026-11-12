import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;

import '../../app_durations.dart';

/// Android page transitions (owner 2026-10-28):
/// - a push slides in from the RIGHT over the page it covers, which stays in
///   place (owner 2026-11-12: the mirror of a back, like a tab's entry), from
///   80 % of the way there (a short slide, not from the edge);
/// - every back — the ← button, the system back button and the predictive
///   back GESTURE — slides the page off to the RIGHT, the page under it
///   already in place. The gesture follows the finger (Android decides
///   commit vs cancel on release; a commit finishes from where the finger
///   let go, a cancel springs back). Without predictive back (older
///   Android) the same slide just plays.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  /// A back slide's length (a gesture's commit takes the rest of it) and its
  /// curve: [AppMotion]'s, like every other arrival and leaving.
  static const popDuration = AppMotion.duration;
  static const popCurve = AppMotion.curve;

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

  static bool _dropping = false;
  static Timer? _droppingEnd;
  static final _dropped = Expando<bool>();

  /// Coming back to a tab that starts over (settings): the pages it drops
  /// leave at once, no back slide, while the tab plays its own entry (the
  /// mirror of [landNextWithoutPush]).
  static void popNextWithoutAnimation() {
    _dropping = true;
    _droppingEnd?.cancel();
    _droppingEnd = Timer(const Duration(milliseconds: 500), () {
      _dropping = false;
      _droppingEnd = null;
    });
  }

  /// Whether [route] pops unseen ([popNextWithoutAnimation]).
  static bool _isDropped(PageRoute<dynamic> route, Animation<double> a) {
    if (_dropped[route] ?? false) return true;
    if (!_dropping || a.status != AnimationStatus.reverse) return false;
    _dropped[route] = true;
    return true;
  }

  @override
  Duration get transitionDuration => AppMotion.duration;

  @override
  Duration get reverseTransitionDuration => popDuration;

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
    return _BackGesture(
      route: route,
      child: _PopSlide(
        route: route,
        animation: animation,
        child: _CoveredRouteGate(
          // The push look only: a back is the slide around it. The page
          // under stays where it is.
          child: _PushSlide(
            animation: _Held(
              animation,
              held: () => landed || _popping(route, animation),
              heldValue: 1,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  static bool _popping(PageRoute<dynamic> route, Animation<double> a) =>
      a.status == AnimationStatus.reverse || _gestureOn(route);

  static bool _gestureOn(PageRoute<dynamic> route) =>
      route.navigator?.userGestureInProgress ?? false;
}

/// Slides its child in from the right, fading in, as [animation] runs 0 → 1.
class _PushSlide extends StatefulWidget {
  const _PushSlide({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_PushSlide> createState() => _PushSlideState();
}

class _PushSlideState extends State<_PushSlide> {
  late CurvedAnimation _curve = _make();

  CurvedAnimation _make() =>
      CurvedAnimation(parent: widget.animation, curve: AppMotion.curve);

  @override
  void didUpdateWidget(_PushSlide old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      _curve.dispose();
      _curve = _make();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    builder: (context, child) => Opacity(
      opacity: AppMotion.enterOpacity(_curve.value).clamp(0.0, 1.0),
      child: FractionalTranslation(
        translation: Offset(AppMotion.enterShift(_curve.value), 0),
        child: child,
      ),
    ),
    child: widget.child,
  );
}

/// [parent], or [heldValue] (with a settled status) while [held].
class _Held extends Animation<double>
    with
        AnimationLazyListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  _Held(this.parent, {required this.held, required this.heldValue});

  final Animation<double> parent;
  final bool Function() held;
  final double heldValue;

  AnimationStatus? _last;

  @override
  double get value => held() ? heldValue : parent.value;

  @override
  AnimationStatus get status => held()
      ? (heldValue >= 1 ? AnimationStatus.completed : AnimationStatus.dismissed)
      : parent.status;

  void _tick() {
    notifyListeners();
    _checkStatus(parent.status);
  }

  void _checkStatus(AnimationStatus _) {
    final s = status;
    if (s == _last) return;
    _last = s;
    notifyStatusListeners(s);
  }

  @override
  void didStartListening() {
    _last = status;
    parent
      ..addListener(_tick)
      ..addStatusListener(_checkStatus);
  }

  @override
  void didStopListening() {
    parent
      ..removeListener(_tick)
      ..removeStatusListener(_checkStatus);
  }
}

/// Slides the page off to the right while it pops (by the finger during a
/// back gesture).
class _PopSlide extends SingleChildRenderObjectWidget {
  const _PopSlide({required this.route, required this.animation, super.child});

  final PageRoute<dynamic> route;
  final Animation<double> animation;

  @override
  _RenderPopSlide createRenderObject(BuildContext context) =>
      _RenderPopSlide(route, animation);

  @override
  void updateRenderObject(BuildContext context, _RenderPopSlide r) => r
    ..route = route
    ..animation = animation;
}

class _RenderPopSlide extends RenderProxyBox {
  _RenderPopSlide(this.route, this._animation);

  PageRoute<dynamic> route;
  Animation<double> _animation;

  /// This pop started under a finger: it stays linear, so the commit carries
  /// on from where the finger let go.
  bool _byFinger = false;

  set animation(Animation<double> value) {
    if (value == _animation) return;
    if (attached) _animation.removeListener(markNeedsPaint);
    _animation = value;
    if (attached) _animation.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsPaint);
    super.detach();
  }

  /// How far right the page sits, a fraction of its width.
  double get _shift {
    final a = _animation;
    final finger = AppPageTransitionsBuilder._gestureOn(route);
    if (!finger && !a.status.isAnimating) _byFinger = false;
    if (finger && a.value < 1) _byFinger = true;
    if (!AppPageTransitionsBuilder._popping(route, a)) return 0;
    final out = (1 - a.value).clamp(0.0, 1.0);
    return _byFinger ? out : AppPageTransitionsBuilder.popCurve.transform(out);
  }

  Offset _offset = Offset.zero;

  bool _hidden = false;

  @override
  void paint(PaintingContext context, Offset offset) {
    // Dropped by a tab that starts over: gone at once, no slide.
    _hidden = AppPageTransitionsBuilder._isDropped(route, _animation);
    if (_hidden) return;
    _offset = Offset(_shift * size.width, 0);
    super.paint(context, offset + _offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      !_hidden &&
      result.addWithPaintOffset(
        offset: _offset,
        position: position,
        hitTest: (result, p) => super.hitTestChildren(result, position: p),
      );

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    transform.translateByDouble(_offset.dx, 0, 0, 1);
  }
}

/// Drives its route by the Android predictive back gesture (Android 14+,
/// enableOnBackInvokedCallback): the page follows the finger, a commit pops
/// it from there, a cancel springs it back.
class _BackGesture extends StatefulWidget {
  const _BackGesture({required this.route, required this.child});

  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<_BackGesture> createState() => _BackGestureState();
}

class _BackGestureState extends State<_BackGesture>
    with WidgetsBindingObserver {
  bool _mine = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = widget.route;
    _mine =
        !backEvent.isButtonEvent && route.isCurrent && route.popGestureEnabled;
    if (_mine) route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return _mine;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_mine) return;
    widget.route.handleUpdateBackGestureProgress(
      progress: 1 - backEvent.progress,
    );
  }

  @override
  void handleCancelBackGesture() {
    if (!_mine) return;
    _mine = false;
    widget.route.handleCancelBackGesture();
  }

  /// Pops from where the finger let go (the framework's own commit restarts
  /// the reverse from fully open: a visible jump for a slide).
  @override
  void handleCommitBackGesture() {
    if (!_mine) return;
    _mine = false;
    final route = widget.route;
    final nav = route.navigator;
    if (nav == null) return;
    if (route.isCurrent) nav.pop();
    final animation = route.animation;
    if (animation == null || !animation.isAnimating) {
      nav.didStopUserGesture();
      return;
    }
    late final AnimationStatusListener done;
    done = (status) {
      if (status.isAnimating) return;
      animation.removeStatusListener(done);
      nav.didStopUserGesture();
    };
    animation.addStatusListener(done);
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
