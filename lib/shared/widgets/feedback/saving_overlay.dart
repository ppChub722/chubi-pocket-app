import 'package:flutter/material.dart';

/// Dims [child], shows a spinner and blocks all input while a save / delete /
/// reorder call is running ([saving]). Skeletons are for the first page load
/// only — every write to the server goes through this.
///
/// ```dart
/// SavingOverlay(
///   saving: state.saving,
///   child: Scaffold(...),
/// )
/// ```
///
/// Wrap the page body (or the whole Scaffold to cover the bars too). The
/// overlay fades in; with `disableAnimations` it just appears.
class SavingOverlay extends StatelessWidget {
  const SavingOverlay({required this.saving, required this.child, super.key});

  final bool saving;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (saving)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 150),
              builder: (context, t, _) => Opacity(
                opacity: t,
                child: ModalBarrier(
                  dismissible: false,
                  color: scheme.scrim.withValues(alpha: 0.32),
                ),
              ),
            ),
          ),
        if (saving)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
