import 'package:flutter/material.dart';

import '../atoms/mirror_surface.dart';

/// The app's glass ([MirrorSurface], like the top bar chips) behind the
/// phone's status bar (clock, battery, signal): the page scrolls under it,
/// so the system icons stay readable (owner 2026-11-12). One strip for the
/// whole app — app.dart's builder wraps every route in it; it only covers
/// the status bar, not the top bar.
class StatusBarScrim extends StatelessWidget {
  const StatusBarScrim({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    if (top <= 0) return child;
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top,
          child: const IgnorePointer(
            // No shadow, no border (owner 2026-11-12): just the glass.
            child: MirrorSurface(
              shape: RoundedRectangleBorder(),
              elevated: false,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}
