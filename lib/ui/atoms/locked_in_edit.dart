import 'package:flutter/material.dart';

import '../tokens/app_opacity.dart';

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
        opacity: locked ? AppOpacity.disabled : 1,
        child: child,
      ),
    );
  }
}
