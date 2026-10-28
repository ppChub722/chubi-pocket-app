import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'nav_layout.dart';
import 'tab_nav.dart';
import '../../ui/ui.dart';

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

  final Map<int, Object?> _topBars = {};

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

  final int? previous;

  final Map<int, Object?> _topBars;
  final Set<int> _claimed;

  static TabSwitchScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabSwitchScope>();

  static int? branchOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BranchIndex>()?.index;

  Object? topBarOf(int branch) => _topBars[branch];

  void reportTopBar(int branch, Object? state) => _topBars[branch] = state;

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

class TabSwipeNudge extends InheritedWidget {
  const TabSwipeNudge({required this.offset, required super.child, super.key});

  final ValueListenable<double> offset;

  static ValueListenable<double>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabSwipeNudge>()?.offset;

  @override
  bool updateShouldNotify(TabSwipeNudge old) => offset != old.offset;
}

class TabSwitchBody extends StatelessWidget {
  const TabSwitchBody({required this.child, super.key});

  final Widget child;

  static const _enterShift = 0.06;

  @override
  Widget build(BuildContext context) {
    final scope = TabSwitchScope.maybeOf(context);
    if (scope == null) return child;
    // The page on top of its tab animates the switch — the container keeps its
    // hands off (it fades only pages without one).
    final branch = TabSwitchScope.branchOf(context);
    if (branch != null && (ModalRoute.isCurrentOf(context) ?? true)) {
      scope.claimSwitch(branch);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: scope.animation, child: child);
    }
    final previous = scope.previous;
    final layout = NavLayoutScope.read(context);
    final bar = previous == null
        ? null
        : layout.barOf(ShellTab.values[previous]);
    final row = bar == null ? const <ShellTab>[] : layout.itemsOf(bar);
    final to = row.indexOf(ShellTab.values[scope.current]);
    final from = previous == null || to < 0
        ? 0.0
        : (to - row.indexOf(ShellTab.values[previous])).sign * _enterShift;
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
