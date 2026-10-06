import 'package:flutter/material.dart';

/// Dims and disables [child] while a page is in edit mode.
///
/// App rule: in edit mode, everything that isn't part of the edit (summary
/// cards, transaction lists, action sections, status pills) fades back and
/// stops taking input, so the user's focus stays on the fields being edited.
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
