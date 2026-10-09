import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_durations.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';

/// The app's one pull-to-refresh (every list / detail / empty page), so
/// the gesture and the look stay identical app-wide.
///
/// Look (owner 2026-10-09 — the stock spinner felt stale): a ฿ coin over a
/// wallet. Pulling grows and spins the coin; once released it keeps
/// dropping into the wallet until [onRefresh] resolves.
///
/// The gesture itself (when it arms, cancels, waits for [onRefresh]) is
/// Flutter's [RefreshIndicator.noSpinner]; this only draws.
///
/// [child] must be a scrollable. For short lists — and empty / error
/// states — give it `physics: const AlwaysScrollableScrollPhysics()` so the
/// pull still fires (`AsyncStateView` does that for its own states).
class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    required this.onRefresh,
    required this.child,
    this.enabled = true,
    super.key,
  });

  /// Called when the user pulls down. Resolve the future when the refresh
  /// completes — the coin keeps dropping until then.
  final Future<void> Function() onRefresh;

  final Widget child;

  /// false = just [child] (a detail page in create mode — nothing to
  /// reload yet).
  final bool enabled;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with TickerProviderStateMixin {
  RefreshIndicatorStatus? _status;

  /// How far the list has been pulled past its top, in px.
  double _pull = 0;
  double _viewport = 0;

  /// One coin drop, repeated while refreshing.
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Fade-out after done / cancel.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: AppDurations.fast,
  );

  @override
  void dispose() {
    _drop.dispose();
    _exit.dispose();
    super.dispose();
  }

  /// 0 → 1 as the pull approaches the point where letting go refreshes —
  /// mirrors [RefreshIndicator]'s own threshold (¼ of the viewport, armed
  /// at ⅔ of that).
  double get _progress {
    if (_viewport <= 0) return 0;
    return (_pull / (_viewport * 0.25 / 1.5)).clamp(0.0, 1.0);
  }

  bool get _refreshing =>
      _status == RefreshIndicatorStatus.snap ||
      _status == RefreshIndicatorStatus.refresh;

  void _onStatus(RefreshIndicatorStatus? status) {
    setState(() => _status = status);
    switch (status) {
      case RefreshIndicatorStatus.drag:
        _pull = 0;
        _exit.value = 0;
      case RefreshIndicatorStatus.snap || RefreshIndicatorStatus.refresh:
        if (!_drop.isAnimating) _drop.repeat();
      case RefreshIndicatorStatus.done || RefreshIndicatorStatus.canceled:
        _exit.forward(from: 0).whenComplete(() {
          if (!mounted) return;
          _drop
            ..stop()
            ..value = 0;
          setState(() {
            _status = null;
            _pull = 0;
          });
        });
      case RefreshIndicatorStatus.armed || null:
        break;
    }
  }

  /// Same bookkeeping [RefreshIndicator] does, to know how far we are.
  bool _track(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axisDirection != AxisDirection.down) {
      return false;
    }
    if (_status == RefreshIndicatorStatus.drag ||
        _status == RefreshIndicatorStatus.armed) {
      _viewport = n.metrics.viewportDimension;
      if (n is ScrollUpdateNotification) {
        _pull -= n.scrollDelta ?? 0;
      } else if (n is OverscrollNotification) {
        _pull -= n.overscroll;
      }
      setState(() => _pull = math.max(0, _pull));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    // Pages float the top bar over their body (extendBodyBehindAppBar),
    // which folds the bar height into the top padding — the coin starts
    // below it. 0 on pages without one.
    final edge = MediaQuery.paddingOf(context).top;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: _onStatus,
          child: NotificationListener<ScrollNotification>(
            onNotification: _track,
            child: widget.child,
          ),
        ),
        if (_status != null)
          Positioned(
            top: edge,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_drop, _exit]),
                builder: (context, _) => CoinDropIndicator(
                  pull: _refreshing ? 1 : _progress,
                  drop: _refreshing ? _drop.value : null,
                  exit: _exit.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The coin-into-wallet mark, drawn for one frame. Public so the widget
/// gallery can show every phase without a real pull.
class CoinDropIndicator extends StatelessWidget {
  const CoinDropIndicator({
    required this.pull,
    this.drop,
    this.exit = 0,
    super.key,
  });

  /// 0 → 1 while pulling (1 = letting go refreshes).
  final double pull;

  /// Position in the drop loop (0 → 1) while refreshing; null = pulling.
  final double? drop;

  /// 0 → 1 while fading out.
  final double exit;

  static const double _bubble = 52;
  static const double _coin = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final refreshing = drop != null;
    final t = drop ?? 0;

    // The bubble slides down with the pull, then rests.
    final dy = refreshing ? 24.0 : -24 + 48 * pull;
    final appear = refreshing ? 1.0 : Curves.easeOut.transform(pull);
    final scale = (0.6 + 0.4 * appear) * (1 - 0.3 * exit);

    // Coin: spins while pulled; while refreshing it falls into the wallet
    // (0 → 0.6), vanishes into it, then respawns on top.
    final double coinY;
    final double coinOpacity;
    final double spin;
    if (!refreshing) {
      coinY = 6;
      coinOpacity = 1;
      spin = pull * 2 * math.pi;
    } else {
      final fall = Curves.easeIn.transform((t / 0.6).clamp(0.0, 1.0));
      coinY = 4 + 18 * fall;
      coinOpacity = t < 0.1
          ? t / 0.1
          : t < 0.55
          ? 1
          : (1 - (t - 0.55) / 0.1).clamp(0.0, 1.0);
      spin = t * 4 * math.pi;
    }
    // Wallet gives a little when the coin lands (0.6 → 0.8).
    final squash = refreshing && t > 0.6 && t < 0.8
        ? math.sin((t - 0.6) / 0.2 * math.pi) * 0.12
        : 0.0;

    return Center(
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Opacity(
          opacity: (appear * (1 - exit)).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: _bubble,
              height: _bubble,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    bottom: 9,
                    child: Transform.scale(
                      scaleX: 1 + squash,
                      scaleY: 1 - squash,
                      alignment: Alignment.bottomCenter,
                      child: Icon(
                        AppIcons.wallet,
                        size: 24,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    top: coinY,
                    child: Opacity(
                      opacity: coinOpacity,
                      child: Transform(
                        alignment: Alignment.center,
                        // A coin turning on its edge.
                        transform: Matrix4.diagonal3Values(
                          math.cos(spin).abs().clamp(0.15, 1.0),
                          1,
                          1,
                        ),
                        child: Container(
                          width: _coin,
                          height: _coin,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.warning,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '฿',
                            style: TextStyle(
                              color: palette.onWarning,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
