import 'package:flutter/material.dart';

class LockedInEdit extends StatelessWidget {
  const LockedInEdit({required this.locked, required this.child, super.key});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: locked,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: locked ? 0.38 : 1,
        child: child,
      ),
    );
  }
}
