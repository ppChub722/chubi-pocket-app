import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

/// Bottom bar shown while a reorder mode is active — Cancel · Undo · Save.
///
/// Domain-agnostic: the consumer wires up its own state (staged tree,
/// in-mode undo stack, dirty flag) and passes the labels + callbacks.
/// Used today by categories; tags / accounts can adopt it as soon as
/// they grow a reorder mode.
///
/// Visual conventions:
/// - Cancel and Save fill the row's flexible space; Undo is a compact
///   filled-tonal `IconButton` that scales in / out via [AnimatedSwitcher]
///   based on [canUndo].
/// - Save is disabled when [canSave] is false (no staged changes).
/// - Wraps in [SafeArea] — drop directly into a `Scaffold.bottomNavigationBar`
///   slot.
class ReorderActionBar extends StatelessWidget {
  const ReorderActionBar({
    required this.canUndo,
    required this.canSave,
    required this.cancelLabel,
    required this.saveLabel,
    required this.undoTooltip,
    required this.onCancel,
    required this.onUndo,
    required this.onSave,
    super.key,
  });

  final bool canUndo;
  final bool canSave;
  final String cancelLabel;
  final String saveLabel;
  final String undoTooltip;
  final VoidCallback onCancel;
  final VoidCallback onUndo;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: canUndo
                  ? IconButton.filledTonal(
                      key: const ValueKey('undo-on'),
                      tooltip: undoTooltip,
                      onPressed: onUndo,
                      icon: const Icon(Icons.undo),
                    )
                  : const SizedBox(
                      key: ValueKey('undo-off'),
                      width: 40,
                      height: 40,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: canSave ? onSave : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(saveLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
