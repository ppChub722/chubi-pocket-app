import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atoms/connection_scope.dart';
import '../atoms/refresh_registry.dart';
import '../atoms/ui_config.dart';
import 'page_pop_observer.dart';
import 'reconnect_reload.dart';
import '../tokens/app_durations.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app/app_colors.dart';

class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    required this.onRefresh,
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Future<void> Function() onRefresh;

  final Widget child;

  final bool enabled;

  /// Set by the app; runs when a pull starts and when it ends (the shell
  /// re-checks its bottom nav then).
  static VoidCallback? onPull;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with TickerProviderStateMixin {
  RefreshIndicatorStatus? _status;

  double _pull = 0;
  double _viewport = 0;

  final OverlayPortalController _portal = OverlayPortalController();

  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: AppDurations.fast,
  );

  int? _reconnects;

  /// When this page's data last loaded: the page loads on open, so start now.
  DateTime? _loadedAt = DateTime.now();

  bool? _tabActive;
  bool? _routeCurrent;
  int _popsWhenCovered = 0;
  bool _showRefreshing = false;
  RefreshRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registry?.unregister(this);
    _registry = RefreshScope.maybeOf(context)
      ?..register(
        this,
        route: ModalRoute.of(context),
        isActive: () =>
            mounted && widget.enabled && TickerMode.valuesOf(context).enabled,
        run: () => _reopen(force: false),
      );
    final now = ConnectionScope.reconnectsOf(context);
    final before = _reconnects;
    _reconnects = now;
    final reconnected = reloadsOnReconnect(before, now);

    var shown = false;
    final active = TickerMode.valuesOf(context).enabled;
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (_tabActive == false && active) shown = true;
    if (_routeCurrent != false && !current) {
      _popsWhenCovered = PagePopObserver.generation;
    }
    if (_routeCurrent == false &&
        current &&
        PagePopObserver.generation != _popsWhenCovered) {
      shown = true;
    }
    _tabActive = active;
    _routeCurrent = current;

    if ((reconnected || shown) && widget.enabled) {
      // Back online / shown again: re-open the page — the same load a pull
      // would run (shown again: only once the data is stale).
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _reopen(force: reconnected),
      );
    }
  }

  Future<void> _reopen({required bool force}) async {
    if (!mounted || !widget.enabled || _showRefreshing) return;
    if (!force && !reopensWhenShown(_loadedAt, DateTime.now())) return;
    _showRefreshing = true;
    try {
      await widget.onRefresh();
      _loadedAt = DateTime.now();
    } catch (_) {
    } finally {
      _showRefreshing = false;
    }
  }

  Future<void> _pulled() async {
    await widget.onRefresh();
    _loadedAt = DateTime.now();
  }

  @override
  void dispose() {
    _registry?.unregister(this);
    _drop.dispose();
    _exit.dispose();
    super.dispose();
  }

  double get _progress {
    if (_viewport <= 0) return 0;
    return (_pull / (_viewport * 0.25 / 1.5)).clamp(0.0, 1.0);
  }

  bool get _refreshing =>
      _status == RefreshIndicatorStatus.snap ||
      _status == RefreshIndicatorStatus.refresh;

  void _onStatus(RefreshIndicatorStatus? status) {
    setState(() => _status = status);
    if (status != null && !_portal.isShowing) _portal.show();
    switch (status) {
      case RefreshIndicatorStatus.drag:
        _pull = 0;
        _exit.value = 0;
        PullToRefresh.onPull?.call();
      case RefreshIndicatorStatus.snap || RefreshIndicatorStatus.refresh:
        if (!_drop.isAnimating) _drop.repeat();
      case RefreshIndicatorStatus.done || RefreshIndicatorStatus.canceled:
        PullToRefresh.onPull?.call();
        _exit.forward(from: 0).whenComplete(() {
          if (!mounted) return;
          _drop
            ..stop()
            ..value = 0;
          if (_portal.isShowing) _portal.hide();
          setState(() {
            _status = null;
            _pull = 0;
          });
        });
      case RefreshIndicatorStatus.armed || null:
        break;
    }
  }

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

  Widget _indicator() => IgnorePointer(
    child: AnimatedBuilder(
      animation: Listenable.merge([_drop, _exit]),
      builder: (context, _) => CoinDropIndicator(
        pull: _refreshing ? 1 : _progress,
        drop: _refreshing ? _drop.value : null,
        exit: _exit.value,
      ),
    ),
  );

  /// On a page the indicator always drops from the same place, just under the
  /// top bar, wherever the scroll area starts; in a sheet it stays on the list.
  Widget _atScreenTop(BuildContext context) {
    if (_status == null) return const SizedBox.shrink();
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    final overlayTop = overlay is RenderBox && overlay.hasSize
        ? overlay.localToGlobal(Offset.zero).dy
        : 0.0;
    final top =
        MediaQueryData.fromView(View.of(context)).padding.top + kToolbarHeight;
    return Positioned(
      top: top - overlayTop,
      left: 0,
      right: 0,
      child: _indicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final list = RefreshIndicator.noSpinner(
      onRefresh: _pulled,
      onStatusChange: _onStatus,
      child: NotificationListener<ScrollNotification>(
        onNotification: _track,
        child: widget.child,
      ),
    );
    final inSheet = ModalRoute.of(context) is PopupRoute;
    if (!inSheet && Overlay.maybeOf(context) != null) {
      return OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _atScreenTop,
        child: list,
      );
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        list,
        if (_status != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: _indicator(),
          ),
      ],
    );
  }
}

class CoinDropIndicator extends StatelessWidget {
  const CoinDropIndicator({
    required this.pull,
    this.drop,
    this.exit = 0,
    super.key,
  });

  final double pull;

  /// Position in the drop loop (0 → 1) while refreshing; null = pulling.
  final double? drop;

  final double exit;

  static const double _bubble = 52;
  static const double _coin = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final refreshing = drop != null;
    final t = drop ?? 0;

    final dy = refreshing ? 24.0 : -24 + 48 * pull;
    final appear = refreshing ? 1.0 : Curves.easeOut.transform(pull);
    final scale = (0.6 + 0.4 * appear) * (1 - 0.3 * exit);

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
                            UiConfig.stringsOf(context).currencySymbol,
                            maxLines: 1,
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
