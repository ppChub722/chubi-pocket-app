import 'package:flutter/material.dart';

import '../atoms/count_badge.dart';
import 'page_dots.dart';

import '../tokens/app_spacing.dart';

class AppTab<T> {
  const AppTab({
    required this.value,
    required this.label,
    this.badgeCount = 0,
    this.icon,
  });

  final T value;
  final String label;
  final int badgeCount;

  /// Shown on every tab when there are 2–3, only on the selected one with 4+.
  final IconData? icon;
}

/// The ONE tab style app-wide (owner 2026-10-21): a pill track with equal
/// segments; the selected pill slides to a tapped tab. Dragging ON THE BAR
/// moves the pill with the finger and snaps to the nearest tab on release.
/// With [pager] the pill rides the page position, so swiping the content
/// moves it too, and a drag on the bar moves the content with it.
/// Always the theme's primary (no per-tab colours).
class AppTabBar<T> extends StatefulWidget {
  const AppTabBar({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.pager,
    this.framed = true,
    super.key,
  });

  final List<AppTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  /// False: no track border (tabs inside a card that already frames them).
  final bool framed;

  /// The [AppTabPager]'s controller, when the tabs page content.
  final PageController? pager;

  static const double height = 40;

  /// The pill's slide, and the [AppTabPager]'s content slide with it.
  static const duration = Duration(milliseconds: 300);
  static const curve = Cubic(0.2, 0.8, 0.2, 1);

  static const pillKey = ValueKey('app-tab-bar-pill');

  @override
  State<AppTabBar<T>> createState() => _AppTabBarState<T>();
}

class _AppTabBarState<T> extends State<AppTabBar<T>> {
  static const _inset = 3.0;

  /// The finger's travel while dragging the bar; null when not dragging.
  double? _drag;

  /// The tab the drag started from (the selection may move under it: the
  /// pager reports pages it passes).
  int _from = 0;
  double _segment = 0;

  int get _index => widget.tabs
      .indexWhere((t) => t.value == widget.selected)
      .clamp(0, 1 << 20);

  PageController? get _pages {
    final p = widget.pager;
    return p != null && p.hasClients && p.position.hasContentDimensions
        ? p
        : null;
  }

  /// Where the pill is, in tabs (0 = first).
  double get _position {
    final drag = _drag;
    if (drag != null && _segment > 0) return _from + drag / _segment;
    return _pages?.page ?? _index.toDouble();
  }

  void _onDragStart(DragStartDetails _) {
    // Mid-slide: start from where the pill is now.
    _from = _position.round();
    setState(() => _drag = (_position - _from) * _segment);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final n = widget.tabs.length;
    final min = -_from * _segment;
    final max = (n - 1 - _from) * _segment;
    setState(() => _drag = ((_drag ?? 0) + d.delta.dx).clamp(min, max));
    // The content follows the finger too.
    final p = _pages;
    if (p != null) p.jumpTo(_position * p.position.viewportDimension);
  }

  void _onDragEnd([DragEndDetails? _]) {
    final n = widget.tabs.length;
    final target = _position.round().clamp(0, n - 1);
    setState(() => _drag = null);
    // Snap the content too (it followed the finger).
    _pages?.animateToPage(
      target,
      duration: AppTabBar.duration,
      curve: AppTabBar.curve,
    );
    final value = widget.tabs[target].value;
    if (value != widget.selected) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final primary = scheme.primary;
    Color wash(double a) =>
        Color.alphaBlend(primary.withValues(alpha: a), scheme.surface);
    final strong = Color.lerp(
      primary,
      dark ? Colors.white : Colors.black,
      dark ? 0.35 : 0.5,
    )!;
    final dragging = _drag != null;
    final pager = widget.pager;
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragEnd,
      child: Container(
        height: AppTabBar.height,
        padding: const EdgeInsets.all(_inset),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTabBar.height / 2),
          border: widget.framed
              ? Border.all(color: scheme.outlineVariant)
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final n = widget.tabs.length;
            _segment = box.maxWidth / n;
            double leftOf(double position) =>
                (position * _segment).clamp(0.0, (n - 1) * _segment);
            final pill = DecoratedBox(
              decoration: BoxDecoration(
                color: wash(dark ? 0.32 : 0.24),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: wash(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: strong.withValues(alpha: 0.12),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // With a pager the pill rides the page (a tap, a content
                // swipe or a bar drag all move the page); without one it
                // animates to the tab itself.
                if (pager != null)
                  AnimatedBuilder(
                    key: AppTabBar.pillKey,
                    animation: pager,
                    builder: (context, child) => Positioned(
                      left: leftOf(_position),
                      width: _segment,
                      top: 0,
                      bottom: 0,
                      child: child!,
                    ),
                    child: pill,
                  )
                else
                  AnimatedPositioned(
                    key: AppTabBar.pillKey,
                    duration: dragging ? Duration.zero : AppTabBar.duration,
                    curve: AppTabBar.curve,
                    left: leftOf(_position),
                    width: _segment,
                    top: 0,
                    bottom: 0,
                    child: pill,
                  ),
                Row(
                  children: [
                    for (final t in widget.tabs)
                      _segmentOf(context, t, n, strong, scheme),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static const double _iconSize = 16;

  /// The count badge beside the label: its gap plus a two-digit width.
  static const double _badgeWidth = AppSpacing.xs + 26;

  /// Whether [label] (+ the icon) fits one segment, its side padding taken.
  bool _fits(
    BuildContext context,
    String label,
    TextStyle style, {
    required bool withIcon,
    bool withBadge = false,
  }) {
    if (_segment <= 0) return true;
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final need =
        painter.width +
        (withIcon ? _iconSize + AppSpacing.xs : 0) +
        (withBadge ? _badgeWidth : 0) +
        AppSpacing.xs * 2;
    painter.dispose();
    return need <= _segment;
  }

  Widget _segmentOf(
    BuildContext context,
    AppTab<T> t,
    int n,
    Color strong,
    ColorScheme scheme,
  ) {
    final active = t.value == widget.selected;
    final tint = active ? strong : scheme.onSurfaceVariant;
    final icon = t.icon;
    final style = Theme.of(context).textTheme.labelLarge!.copyWith(
      fontSize: 14,
      color: tint,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
    );
    // Icons: every tab with 2–3 tabs, the selected one with 4+, and only
    // when icon + label fit the segment (a narrow phone drops the icon
    // rather than cut the word, owner 2026-10-21).
    final showIcon =
        icon != null &&
        (n <= 3 || active) &&
        _fits(
          context,
          t.label,
          style,
          withIcon: true,
          withBadge: t.badgeCount > 0,
        );
    final text = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: style,
      child: Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(icon, size: _iconSize, color: tint),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(child: text),
        if (t.badgeCount > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          CountBadge(count: t.badgeCount),
        ],
      ],
    );
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onChanged(t.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Center(child: label),
          ),
        ),
      ),
    );
  }
}

/// The tabs' pages. Changing tab slides the content with the pill (same
/// duration and curve); swiping the content changes tabs too, and the bar's
/// pill rides along (owner 2026-10-21: swipe works on both).
class AppTabPager<T> extends StatefulWidget {
  const AppTabPager({
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.controller,
    required this.builder,
    this.enabled = true,
    this.showPageDots = true,
    super.key,
  });

  final List<T> values;
  final T selected;

  final ValueChanged<T> onChanged;
  final PageController controller;
  final Widget Function(BuildContext context, T value) builder;

  /// False = the content can't be swiped (edit / reorder modes).
  final bool enabled;

  final bool showPageDots;

  static const duration = AppTabBar.duration;
  static const curve = AppTabBar.curve;

  @override
  State<AppTabPager<T>> createState() => _AppTabPagerState<T>();
}

class _AppTabPagerState<T> extends State<AppTabPager<T>> {
  bool _sliding = false;

  @override
  void didUpdateWidget(AppTabPager<T> old) {
    super.didUpdateWidget(old);
    final c = widget.controller;
    final i = widget.values.indexOf(widget.selected);
    if (i < 0 || !c.hasClients || (c.page ?? -1).round() == i) return;
    _sliding = true;
    c
        .animateToPage(
          i,
          duration: AppTabPager.duration,
          curve: AppTabPager.curve,
        )
        .whenComplete(() => _sliding = false);
  }

  void _onPage(int i) {
    if (_sliding) return;
    final v = widget.values[i];
    if (v != widget.selected) widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: widget.controller,
      physics: widget.enabled
          ? const _SnappyPagePhysics()
          : const NeverScrollableScrollPhysics(),
      onPageChanged: _onPage,
      children: [
        for (var i = 0; i < widget.values.length; i++)
          _KeepAlive(
            child: widget.showPageDots && widget.values.length > 1
                ? PageDotsScope(
                    count: widget.values.length,
                    index: i,
                    child: Builder(
                      builder: (c) => widget.builder(c, widget.values[i]),
                    ),
                  )
                : Builder(builder: (c) => widget.builder(c, widget.values[i])),
          ),
      ],
    );
  }
}

class _SnappyPagePhysics extends PageScrollPhysics {
  const _SnappyPagePhysics({super.parent});

  @override
  _SnappyPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _SnappyPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 260, ratio: 1);
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
