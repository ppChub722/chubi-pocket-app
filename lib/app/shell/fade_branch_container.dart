import 'package:flutter/material.dart';

import '../../core/constants/app_durations.dart';

/// Tab-switch container for the shell: keeps every branch alive in an
/// [IndexedStack] (state + scroll preserved) and runs a fade / lift each
/// time the selected tab changes.
///
/// The container itself doesn't animate anything — that would move the
/// top bar too (owner 2026-10-09: the bar must stay put across tabs). It
/// only publishes a [TabSwitchScope]: [TabSwitchBody] (used by tab-root
/// bodies) fades the page under the bar, and `AppTopBar` uses it to slide
/// its left group in / out when one tab has it and the other doesn't.
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

  @override
  void didUpdateWidget(FadeBranchContainer old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _previous = old.currentIndex;
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
                  child: _BranchIndex(index: i, child: widget.children[i]),
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
    required super.child,
  }) : _topBars = topBars;

  /// 0 → 1 after each switch; sits at 1 otherwise.
  final Animation<double> animation;
  final int current;

  /// The tab before the latest switch (null before the first one).
  final int? previous;

  final Map<int, Object?> _topBars;

  /// Null outside the shell (overlay pages, tests, dev previews).
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

/// Fades / lifts [child] in when the shell switches tabs. Wrap a page's
/// body with it — never the Scaffold, so the top bar stays still. Outside
/// the shell (tests, dev previews) it's a no-op.
class TabSwitchBody extends StatelessWidget {
  const TabSwitchBody({required this.child, super.key});

  final Widget child;

  static final Animatable<Offset> _lift = Tween<Offset>(
    begin: const Offset(0, 0.015),
    end: Offset.zero,
  );

  @override
  Widget build(BuildContext context) {
    final scope = TabSwitchScope.maybeOf(context);
    if (scope == null) return child;
    return FadeTransition(
      opacity: scope.animation,
      child: SlideTransition(
        position: scope.animation.drive(_lift),
        child: child,
      ),
    );
  }
}
