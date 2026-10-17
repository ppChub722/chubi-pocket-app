import '../atoms/app_icon_button.dart';
import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/app_button.dart';

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
                    ? AppIconButton(
                        key: const ValueKey('undo-on'),
                        tooltip: undoTooltip,
                        onPressed: onUndo,
                        icon: AppIcons.undo,
                      )
                    : const SizedBox(
                        key: ValueKey('undo-off'),
                        width: AppIconButton.sizeBar,
                        height: AppIconButton.sizeBar,
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
                submits: true,
                onPressed: canSave ? onSave : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
