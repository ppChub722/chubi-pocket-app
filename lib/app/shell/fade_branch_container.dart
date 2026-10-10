import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/constants/app_durations.dart';
import 'tab_nav.dart';

/// Tab-switch container for the shell: keeps every branch alive in an
/// [IndexedStack] (state + scroll preserved) and runs a fade / slide each
/// time the selected tab changes.
///
/// A tab root's switch is animated by the page, not here — that would move
/// the top bar too (owner 2026-10-09: the bar must stay put across tabs).
/// The container publishes a [TabSwitchScope]: [TabSwitchBody] (used by
/// tab-root bodies) fades the page under the bar, and `AppTopBar` uses it
/// to slide its left group in / out when one tab has it and the other
/// doesn't. Only a tab that lands on a page with no [TabSwitchBody] (a
/// detail page — history restore, an `openPage` jump) is faded whole here.
class FadeBranchContainer extends StatefulWidget {
  const FadeBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadeBranchContainer> createState() => _FadeBranchContainerState();
}

class _FadeBranchContainerState extends State<FadeBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDurations.chrome,
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _ctrl,
    curve: AppDurations.chromeCurve,
  );
  int? _previous;

  /// What each branch's visible top bar shows — written by the bars.
  final Map<int, Object?> _topBars = {};

  /// Branches whose visible page animates the switch itself
  /// ([TabSwitchBody]) — re-claimed on every switch.
  final Set<int> _claimed = {};

  @override
  void didUpdateWidget(FadeBranchContainer old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _previous = old.currentIndex;
      // The arriving tab's page claims it again while this frame builds
      // (TabSwitchBody depends on the scope, so it rebuilds now).
      _claimed.remove(widget.currentIndex);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabSwitchScope._(
      animation: _curve,
      current: widget.currentIndex,
      previous: _previous,
      topBars: _topBars,
      claimed: _claimed,
      child: IndexedStack(
        index: widget.currentIndex,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            // Inactive branches stay mounted but out of the semantics tree,
            // out of hero flights (every branch's top bar uses the same hero
            // tags, and a root push would see them all) and with tickers
            // off — no hidden animations, and their pages stop claiming the
            // back gesture (AppPageTransitionsBuilder).
            TickerMode(
              enabled: i == widget.currentIndex,
              child: ExcludeSemantics(
                excluding: i != widget.currentIndex,
                child: HeroMode(
                  enabled: i == widget.currentIndex,
                  child: _UnclaimedFade(
                    animation: _curve,
                    claimed: () => _claimed.contains(i),
                    child: _BranchIndex(index: i, child: widget.children[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The shell's tab-switch state, for widgets inside a branch.
class TabSwitchScope extends InheritedWidget {
  const TabSwitchScope._({
    required this.animation,
    required this.current,
    required this.previous,
    required Map<int, Object?> topBars,
    required Set<int> claimed,
    required super.child,
  }) : _topBars = topBars,
       _claimed = claimed;

  /// 0 → 1 after each switch; sits at 1 otherwise.
  final Animation<double> animation;
  final int current;

  /// The tab before the latest switch (null before the first one).
  final int? previous;

  final Map<int, Object?> _topBars;
  final Set<int> _claimed;

  /// Null outside the shell (tests, dev previews).
  static TabSwitchScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabSwitchScope>();

  /// The branch [context] lives in, or null outside the shell.
  static int? branchOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BranchIndex>()?.index;

  /// What branch [branch]'s visible top bar last showed (opaque to us).
  Object? topBarOf(int branch) => _topBars[branch];

  /// A branch's visible top bar records what it shows. No rebuild — read
  /// on the next switch.
  void reportTopBar(int branch, Object? state) => _topBars[branch] = state;

  /// The visible page of [branch] animates the switch itself — the
  /// container leaves that tab alone. No rebuild.
  void claimSwitch(int branch) => _claimed.add(branch);

  @override
  bool updateShouldNotify(TabSwitchScope old) =>
      animation != old.animation ||
      current != old.current ||
      previous != old.previous;
}

class _BranchIndex extends InheritedWidget {
  const _BranchIndex({required this.index, required super.child});

  final int index;

  @override
  bool updateShouldNotify(_BranchIndex old) => index != old.index;
}

/// Fades its branch in on a switch unless the visible page [claimed] it.
/// Decided at paint time, after the arriving page has built and claimed —
/// so a tab root never fades its top bar, and a detail page never snaps.
class _UnclaimedFade extends SingleChildRenderObjectWidget {
  const _UnclaimedFade({
    required this.animation,
    required this.claimed,
    super.child,
  });

  final Animation<double> animation;
  final bool Function() claimed;

  @override
  _RenderUnclaimedFade createRenderObject(BuildContext context) =>
      _RenderUnclaimedFade(animation, claimed);

  @override
  void updateRenderObject(BuildContext context, _RenderUnclaimedFade r) => r
    ..animation = animation
    ..claimed = claimed;
}

class _RenderUnclaimedFade extends RenderProxyBox {
  _RenderUnclaimedFade(this._animation, this.claimed);

  Animation<double> _animation;
  bool Function() claimed;

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

  // It may push an opacity layer on any frame of a switch.
  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final opacity = claimed() ? 1.0 : _animation.value;
    if (opacity >= 1) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    layer = context.pushOpacity(
      offset,
      (opacity * 255).round(),
      super.paint,
      oldLayer: layer as OpacityLayer?,
    );
  }
}

/// How far (px) the visible tab body trails the finger during a sideways
/// swipe on a tab root — a small fake "the page is moving" cue before the
/// switch (owner 2026-10-09). Provided by `MainShell`; sits at 0 otherwise.
class TabSwipeNudge extends InheritedWidget {
  const TabSwipeNudge({required this.offset, required super.child, super.key});

  final ValueListenable<double> offset;

  static ValueListenable<double>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabSwipeNudge>()?.offset;

  @override
  bool updateShouldNotify(TabSwipeNudge old) => offset != old.offset;
}

/// Fades / slides [child] in when the shell switches tabs, and follows the
/// [TabSwipeNudge] mid-swipe. Wrap a page's body with it — never the
/// Scaffold, so the top bar stays still. Outside the shell (tests, dev
/// previews) it's a no-op.
class TabSwitchBody extends StatelessWidget {
  const TabSwitchBody({required this.child, super.key});

  final Widget child;

  /// Entry slide, as a fraction of the body's width.
  static const _enterShift = 0.06;

  @override
  Widget build(BuildContext context) {
    final scope = TabSwitchScope.maybeOf(context);
    if (scope == null) return child;
    // The page on top of its tab animates the switch — the container
    // keeps its hands off (it fades only pages without one).
    final branch = TabSwitchScope.branchOf(context);
    if (branch != null && (ModalRoute.isCurrentOf(context) ?? true)) {
      scope.claimSwitch(branch);
    }
    // Reduced motion (system setting): a plain fade — no slide, no nudge.
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: scope.animation, child: child);
    }
    final previous = scope.previous;
    // Tabs sit in rows (ShellRow), so within one the new body comes in
    // from the side it lies on — a tab to the right slides in from the
    // right, whether it was swiped to, tapped or backed into. Across rows
    // (a เพิ่มเติม card from the hub, a ⏳ 🔔 👤 chip) there's no side: it
    // just fades.
    final from = previous == null
        ? 0.0
        : ShellTab.values[previous].sideOf(ShellTab.values[scope.current]) *
              _enterShift;
    final Widget body = FadeTransition(
      opacity: scope.animation,
      child: SlideTransition(
        position: scope.animation.drive(
          Tween<Offset>(begin: Offset(from, 0), end: Offset.zero),
        ),
        child: child,
      ),
    );
    final nudge = TabSwipeNudge.maybeOf(context);
    if (nudge == null) return body;
    return ValueListenableBuilder<double>(
      valueListenable: nudge,
      builder: (context, dx, body) =>
          Transform.translate(offset: Offset(dx, 0), child: body),
      child: body,
    );
  }
}
