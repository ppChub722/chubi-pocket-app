import 'package:flutter/material.dart';

import '../atoms/count_badge.dart';
import 'page_dots.dart';

import '../tokens/app_spacing.dart';

/// One tab of an [AppTabBar].
///
/// [icon] before the label — REQUIRED in spirit for a bar whose pages don't
/// swipe (a mode switch, e.g. quick create's รายการ · หนี้ · ออม): with no
/// finger-following page to explain it, the icon says what each tab is.
/// [color] tints the selected tab and the underline (a mode's own colour);
/// null = the theme primary.
class AppTab<T> {
  const AppTab({
    required this.value,
    required this.label,
    this.badgeCount = 0,
    this.icon,
    this.color,
  });

  final T value;
  final String label;
  final int badgeCount;
  final IconData? icon;
  final Color? color;
}

/// Equal-width underline tab bar (categories' expense/income tabs style).
/// Value-driven — no `TabController` needed; the page swaps its body on
/// [onChanged]. The underline is one indicator that slides to the selected
/// tab. Put the body in an [AppTabPager] (and pass its [pager] here) to
/// swipe between tabs with the underline following the finger.
class AppTabBar<T> extends StatelessWidget {
  const AppTabBar({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.pager,
    super.key,
  });

  final List<AppTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  /// The [AppTabPager]'s controller — the underline then tracks the page
  /// position (mid-swipe included) instead of jumping per tab.
  final PageController? pager;

  static const _slide = Duration(milliseconds: 240);

  /// The underline's key (tests measure its position).
  static const underlineKey = ValueKey('app-tab-bar-underline');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = tabs.indexWhere((t) => t.value == selected);
    final pager = this.pager;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / tabs.length;
          final underline = ColoredBox(
            key: underlineKey,
            color: (index >= 0 ? tabs[index].color : null) ?? scheme.primary,
          );
          return Stack(
            children: [
              Row(children: [for (final t in tabs) _tab(context, scheme, t)]),
              if (pager != null)
                AnimatedBuilder(
                  animation: pager,
                  builder: (context, child) {
                    final page =
                        pager.hasClients && pager.position.hasContentDimensions
                        ? pager.page ?? index.toDouble()
                        : index.toDouble();
                    return Positioned(
                      left: page * w,
                      width: w,
                      bottom: 0,
                      height: 2.5,
                      child: child!,
                    );
                  },
                  child: underline,
                )
              else if (index >= 0)
                AnimatedPositioned(
                  duration: _slide,
                  curve: Curves.easeOutCubic,
                  left: index * w,
                  width: w,
                  bottom: 0,
                  height: 2.5,
                  child: underline,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tab(BuildContext context, ColorScheme scheme, AppTab<T> t) {
    final active = t.value == selected;
    final tint = active ? (t.color ?? scheme.primary) : scheme.onSurfaceVariant;
    final text = AnimatedDefaultTextStyle(
      duration: _slide,
      curve: Curves.easeOutCubic,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
        color: tint,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
      ),
      child: Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    final label = t.icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(t.icon, size: 18, color: tint),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: text),
            ],
          );
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(t.value),
        child: Padding(
          // Bottom: room for the indicator.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md + 2.5,
          ),
          child: Center(
            // The shared count badge, floating off the label's top-right.
            child: CountBadge.floating(
              child: label,
              count: t.badgeCount,
              offset: const Offset(-14, -10),
            ),
          ),
        ),
      ),
    );
  }
}

/// The body under an [AppTabBar], one page per tab: the content follows
/// the finger sideways and settles on a tab; tapping a tab slides there
/// slow → fast → slow (owner 2026-10-09: this, not a fling-and-cut, app
/// wide). Pages stay alive off-screen (scroll, filters, loaded data).
///
/// The page owns [controller] — create it with `initialPage` = the
/// selected tab's index — and passes it to [AppTabBar.pager] too, so the
/// underline tracks the swipe.
///
/// [enabled] false stops paging via physics only — the tree doesn't
/// change, so a long-press that turns into a drag mid-gesture (reorder)
/// isn't torn down. Each page builds its own scrollables: a
/// `ScrollController` must not be shared between pages.
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

  /// Tab values, in bar order.
  final List<T> values;
  final T selected;

  /// A swipe landed on another tab.
  final ValueChanged<T> onChanged;
  final PageController controller;
  final Widget Function(BuildContext context, T value) builder;
  final bool enabled;

  /// Each page ends with the [PageDots]: a `ListPageBody` inside adds them
  /// itself (via [PageDotsScope]); a custom scrollable puts a
  /// [PageDotsFooter] last.
  final bool showPageDots;

  /// A tap on the bar → this slide.
  static const duration = Duration(milliseconds: 320);
  static const curve = Curves.easeInOutCubic;

  @override
  State<AppTabPager<T>> createState() => _AppTabPagerState<T>();
}

class _AppTabPagerState<T> extends State<AppTabPager<T>> {
  /// A tap-driven slide is running — the pages it passes aren't picks.
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

/// Paging with a stiffer spring — a released swipe settles quicker than
/// the stock page physics.
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
