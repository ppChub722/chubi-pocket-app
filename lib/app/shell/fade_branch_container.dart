import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'nav_layout.dart';
import 'tab_entry.dart';
import 'tab_nav.dart';
import '../../ui/tokens/app/theme/app_page_transitions.dart';
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
      final slide = TabBackSlideScope.maybeOf(context);
      final back = slide?._takeArrival(widget.currentIndex) ?? false;
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
        back: back,
        reducedMotion: MediaQuery.disableAnimationsOf(context),
      );
      if (_entry.kind == TabEntryKind.none) {
        _ctrl.value = 1;
      } else {
        _ctrl.forward(from: 0);
      }
      // Any switch ends a back slide: what it uncovered is the tab now.
      slide?._reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static final _noUnderlay = ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    final slide = TabBackSlideScope.maybeOf(context);
    return TabSwitchScope._(
      animation: _curve,
      entry: _entry,
      current: widget.currentIndex,
      previous: _previous,
      topBars: _topBars,
      claimed: _claimed,
      child: ValueListenableBuilder<int?>(
        valueListenable: slide?.underlay ?? _noUnderlay,
        builder: (context, under, _) => _branches(slide, under),
      ),
    );
  }

  /// Every branch kept alive; only the current one shows, plus, during a
  /// back between tabs, the one it goes back to, under it.
  Widget _branches(TabBackSlide? slide, int? under) {
    final current = widget.currentIndex;
    final below = under == current ? null : under;
    final order = [
      for (var i = 0; i < widget.children.length; i++)
        if (i != current && i != below) i,
      ?below,
      current,
    ];
    return _BranchLayers(
      children: [
        for (final i in order)
          Offstage(
            key: ValueKey(i),
            offstage: i != current && i != below,
            child: TickerMode(
              enabled: i == current,
              child: ExcludeSemantics(
                excluding: i != current,
                child: HeroMode(
                  enabled: i == current,
                  child: _BackSlidePaint(
                    progress: slide?.progress,
                    active: i == current && below != null,
                    child: _EntryPaint(
                      animation: _curve,
                      entry: () => _entry,
                      // A page with a TabSwitchBody animates its body itself.
                      active: () => !_claimed.contains(i),
                      child: _BranchIndex(index: i, child: widget.children[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The branches on top of each other, each filling the container, painted
/// in order (the IndexedStack that can show a second branch under the
/// current one); offstage ones are kept but not painted.
class _BranchLayers extends MultiChildRenderObjectWidget {
  const _BranchLayers({super.children});

  @override
  RenderStack createRenderObject(BuildContext context) => RenderStack(
    alignment: Alignment.topLeft,
    fit: StackFit.expand,
    textDirection: Directionality.maybeOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderStack r) =>
      r.textDirection = Directionality.maybeOf(context);
}

/// A back between tabs (owner 2026-10-28): the open tab slides off to the
/// right over the tab it goes back to ([underlay]), by the finger with the
/// predictive back gesture. Owned by the shell, played by
/// [FadeBranchContainer].
class TabBackSlide {
  TabBackSlide({required TickerProvider vsync})
    : progress = AnimationController(vsync: vsync);

  /// 0 = in place, 1 = gone off the right edge.
  final AnimationController progress;

  /// The branch shown under the sliding one; null when no back is under way.
  final ValueNotifier<int?> underlay = ValueNotifier(null);

  int? _arriving;

  /// The next switch to [branch] finishes this back: it lands in place.
  void arriveAt(int branch) => _arriving = branch;

  bool _takeArrival(int branch) {
    final hit = _arriving == branch;
    _arriving = null;
    return hit;
  }

  /// Drops a back under way (the switch it led to never came).
  void abort() => _reset();

  void _reset() {
    _arriving = null;
    underlay.value = null;
    progress.value = 0;
  }

  /// Back in place (a cancelled gesture).
  Future<void> cancel() async {
    await _run(
      progress.animateTo(
        0,
        duration: _remaining(progress.value),
        curve: Curves.easeOutCubic,
      ),
    );
    if (progress.value == 0) underlay.value = null;
  }

  /// Off the right edge from wherever it is; true when it got there.
  Future<bool> finish({Curve curve = Curves.linear}) async {
    await _run(
      progress.animateTo(
        1,
        duration: _remaining(1 - progress.value),
        curve: curve,
      ),
    );
    return progress.value >= 1 && underlay.value != null;
  }

  static Future<void> _run(TickerFuture f) {
    final done = Completer<void>();
    f.whenCompleteOrCancel(done.complete);
    return done.future;
  }

  static Duration _remaining(double fraction) =>
      AppPageTransitionsBuilder.popDuration * fraction.clamp(0.0, 1.0);

  void dispose() {
    progress.dispose();
    underlay.dispose();
  }
}

class TabBackSlideScope extends InheritedWidget {
  const TabBackSlideScope({
    required this.slide,
    required super.child,
    super.key,
  });

  final TabBackSlide slide;

  static TabBackSlide? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabBackSlideScope>()?.slide;

  @override
  bool updateShouldNotify(TabBackSlideScope old) => slide != old.slide;
}

/// Shifts its child right by [progress] x its width while [active].
class _BackSlidePaint extends SingleChildRenderObjectWidget {
  const _BackSlidePaint({
    required this.progress,
    required this.active,
    super.child,
  });

  final Animation<double>? progress;
  final bool active;

  @override
  _RenderBackSlide createRenderObject(BuildContext context) =>
      _RenderBackSlide(progress, active);

  @override
  void updateRenderObject(BuildContext context, _RenderBackSlide r) => r
    ..progress = progress
    ..active = active;
}

class _RenderBackSlide extends RenderProxyBox {
  _RenderBackSlide(this._progress, this._active);

  Animation<double>? _progress;
  bool _active;

  set progress(Animation<double>? value) {
    if (value == _progress) return;
    if (attached) _progress?.removeListener(markNeedsPaint);
    _progress = value;
    if (attached) _progress?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set active(bool value) {
    if (value == _active) return;
    _active = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress?.removeListener(markNeedsPaint);
    super.detach();
  }

  Offset _offset = Offset.zero;

  @override
  void paint(PaintingContext context, Offset offset) {
    final p = _active ? (_progress?.value ?? 0) : 0.0;
    _offset = Offset(p.clamp(0.0, 1.0) * size.width, 0);
    super.paint(context, offset + _offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
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
