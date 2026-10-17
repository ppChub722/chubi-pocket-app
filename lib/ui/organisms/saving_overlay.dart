import 'package:flutter/material.dart';

import '../atoms/app_spinner.dart';

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
              child: Center(child: AppSpinner(size: AppSpinnerSize.large)),
            ),
          ),
      ],
    );
  }
}
