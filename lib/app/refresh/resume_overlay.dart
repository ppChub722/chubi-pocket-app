import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Covers the app with a spinner while [busy]; what is underneath stays in place.
class ResumeOverlay extends StatelessWidget {
  const ResumeOverlay({required this.busy, required this.child, super.key});

  final ValueListenable<bool> busy;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      child,
      ValueListenableBuilder<bool>(
        valueListenable: busy,
        builder: (context, on, _) => on
            ? Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.72),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}
