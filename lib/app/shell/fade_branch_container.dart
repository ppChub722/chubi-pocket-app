import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'nav_layout.dart';
import 'tab_entry.dart';
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

  TabEntry _entry = TabEntry.none;

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
      final box = context.findRenderObject() as RenderBox?;
      final size = box != null && box.hasSize
          ? box.size
          : MediaQuery.sizeOf(context);
      final origin = ShellEntryOrigin.take();
      _entry = resolveTabEntry(
        from: ShellTab.values[old.currentIndex],
        to: ShellTab.values[widget.currentIndex],
        layout: NavLayoutScope.read(context),
        origin: origin == null ? null : originAlignment(origin, size),
        reducedMotion: MediaQuery.disableAnimationsOf(context),
      );
      if (_entry.kind == TabEntryKind.none) {
        _ctrl.value = 1;
      } else {
        _ctrl.forward(from: 0);
      }
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
      entry: _entry,
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
                  child: _EntryPaint(
                    animation: _curve,
                    entry: () => _entry,
                    // A page with a TabSwitchBody animates the body itself.
                    active: () => !_claimed.contains(i),
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
    required this.entry,
    required this.current,
    required this.previous,
    required Map<int, Object?> topBars,
    required Set<int> claimed,
    required super.child,
  }) : _topBars = topBars,
       _claimed = claimed;

  /// 0 → 1 after each switch; sits at 1 otherwise.
  final Animation<double> animation;

  /// How the current tab arrives ([resolveTabEntry]).
  final TabEntry entry;
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
      entry != old.entry ||
      current != old.current ||
      previous != old.previous;
}

class _BranchIndex extends InheritedWidget {
  const _BranchIndex({required this.index, required super.child});

  final int index;

  @override
  bool updateShouldNotify(_BranchIndex old) => index != old.index;
}

/// Paints its child arriving per [entry] (fade + shift / grow) while
/// [animation] runs, when [active].
class _EntryPaint extends SingleChildRenderObjectWidget {
  const _EntryPaint({
    required this.animation,
    required this.entry,
    required this.active,
    super.child,
  });

  final Animation<double> animation;
  final TabEntry Function() entry;
  final bool Function() active;

  @override
  _RenderEntryPaint createRenderObject(BuildContext context) =>
      _RenderEntryPaint(animation, entry, active);

  @override
  void updateRenderObject(BuildContext context, _RenderEntryPaint r) => r
    ..animation = animation
    ..entry = entry
    ..active = active;
}

class _RenderEntryPaint extends RenderProxyBox {
  _RenderEntryPaint(this._animation, this.entry, this.active);

  Animation<double> _animation;
  TabEntry Function() entry;
  bool Function() active;

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
    final t = _animation.value;
    final e = entry();
    if (!active() || t >= 1 || e.kind == TabEntryKind.none) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    final transform = e.transformAt(t, size);
    layer = context.pushOpacity(
      offset,
      (e.opacityAt(t).clamp(0.0, 1.0) * 255).round(),
      (context, offset) => context.pushTransform(
        needsCompositing,
        offset,
        transform,
        super.paint,
      ),
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

/// A tab root page's body: it plays the tab switch itself (the top bar stays
/// put) — see [TabEntry] for how it arrives — and trails a body swipe.
class TabSwitchBody extends StatelessWidget {
  const TabSwitchBody({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = TabSwitchScope.maybeOf(context);
    if (scope == null) return child;
    // The page on top of its tab animates the switch — the container keeps its
    // hands off (it plays it only for pages without one).
    final branch = TabSwitchScope.branchOf(context);
    if (branch != null && (ModalRoute.isCurrentOf(context) ?? true)) {
      scope.claimSwitch(branch);
    }
    final entry = scope.entry;
    final Widget body = _EntryPaint(
      animation: scope.animation,
      entry: () => entry,
      active: () => true,
      child: child,
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
