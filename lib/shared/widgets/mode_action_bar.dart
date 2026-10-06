import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import 'buttons/app_button.dart';

/// Bottom bar shown while a page is in edit / reorder mode or is a form —
/// Cancel · Undo · Save. Replaces the shell's bottom nav + FAB (the page
/// calls `ShellChrome.hide()` on entry) so it's the only bar on screen.
///
/// Domain-agnostic: the page owns its staged state, undo stack and dirty
/// flag and passes labels + callbacks.
/// - Undo is a compact tonal icon button that scales in when [canUndo].
///   Omit [onUndo] for screens without undo (plain forms).
/// - Save is disabled while [canSave] is false; [saving] shows a spinner.
/// - Wraps in [SafeArea] — drop straight into `Scaffold.bottomNavigationBar`.
class ModeActionBar extends StatelessWidget {
  const ModeActionBar({
    required this.canSave,
    required this.cancelLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
    this.canUndo = false,
    this.undoTooltip,
    this.onUndo,
    this.saving = false,
    super.key,
  });

  final bool canUndo;
  final bool canSave;
  final bool saving;
  final String cancelLabel;
  final String saveLabel;
  final String? undoTooltip;
  final VoidCallback onCancel;
  final VoidCallback? onUndo;
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
              child: AppButton(
                label: cancelLabel,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.large,
                expand: true,
                onPressed: saving ? null : onCancel,
              ),
            ),
            if (onUndo != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: canUndo && !saving
                    ? IconButton.filledTonal(
                        key: const ValueKey('undo-on'),
                        tooltip: undoTooltip,
                        onPressed: onUndo,
                        icon: const Icon(AppIcons.undo),
                      )
                    : const SizedBox(
                        key: ValueKey('undo-off'),
                        width: 40,
                        height: 40,
                      ),
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: saveLabel,
                size: AppButtonSize.large,
                expand: true,
                loading: saving,
                onPressed: canSave ? onSave : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
