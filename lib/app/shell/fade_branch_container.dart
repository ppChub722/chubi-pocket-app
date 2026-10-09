import 'package:flutter/material.dart';

/// Tab-switch container for the shell: keeps every branch alive in an
/// [IndexedStack] (state + scroll preserved) but fades / lifts the newly
/// selected tab in, so switching reads as a transition instead of a hard cut.
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
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.015),
    end: Offset.zero,
  ).animate(_curve);

  @override
  void didUpdateWidget(FadeBranchContainer old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: _slide,
        child: IndexedStack(
          index: widget.currentIndex,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              // Inactive branches stay mounted but out of the semantics tree.
              ExcludeSemantics(
                excluding: i != widget.currentIndex,
                child: widget.children[i],
              ),
          ],
        ),
      ),
    );
  }
}
