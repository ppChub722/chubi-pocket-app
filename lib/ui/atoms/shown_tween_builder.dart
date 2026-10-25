import 'package:flutter/material.dart';

/// A [TweenAnimationBuilder] that plays again from [tween]'s begin every time
/// its page is shown: first open (after the page's push), back from another
/// tab or page, a tab inside the page selected again, the app resumed. A new
/// value alone animates from the old one, as before.
class ShownTweenBuilder<T extends Object?> extends StatefulWidget {
  const ShownTweenBuilder({
    required this.tween,
    required this.duration,
    required this.builder,
    this.curve = Curves.linear,
    this.child,
    super.key,
  });

  final Tween<T> tween;
  final Duration duration;
  final Curve curve;
  final ValueWidgetBuilder<T> builder;
  final Widget? child;

  /// Bumped on app resume: every builder on screen plays again.
  static final ValueNotifier<int> replayAll = ValueNotifier(0);

  @override
  State<ShownTweenBuilder<T>> createState() => _ShownTweenBuilderState<T>();
}

class _ShownTweenBuilderState<T extends Object?>
    extends State<ShownTweenBuilder<T>> {
  int _gen = 0;
  bool? _shown;
  Animation<double>? _route;
  bool _awaitingRoute = false;

  @override
  void initState() {
    super.initState();
    ShownTweenBuilder.replayAll.addListener(_replay);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.valuesOf(context).enabled;
    if (_shown == false && shown) _gen++;
    _shown = shown;
    final route = ModalRoute.of(context)?.animation;
    if (route != _route) {
      _route?.removeStatusListener(_onRoute);
      _route = route;
      // First open: hold at the start until the push ends, or it plays unseen.
      _awaitingRoute =
          _gen == 0 && route != null && route.status == AnimationStatus.forward;
      if (_awaitingRoute) route!.addStatusListener(_onRoute);
    }
  }

  void _onRoute(AnimationStatus status) {
    if (!status.isCompleted) return;
    _route?.removeStatusListener(_onRoute);
    if (mounted) setState(() => _awaitingRoute = false);
  }

  void _replay() {
    if (mounted && (_shown ?? true)) setState(() => _gen++);
  }

  @override
  void dispose() {
    ShownTweenBuilder.replayAll.removeListener(_replay);
    _route?.removeStatusListener(_onRoute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    if (MediaQuery.disableAnimationsOf(context)) {
      return w.builder(context, w.tween.end as T, w.child);
    }
    if (_awaitingRoute) return w.builder(context, w.tween.begin as T, w.child);
    return TweenAnimationBuilder<T>(
      key: ValueKey(_gen),
      tween: w.tween,
      duration: w.duration,
      curve: w.curve,
      builder: w.builder,
      child: w.child,
    );
  }
}
