import '../atoms/app_icon_button.dart';
import 'package:flutter/material.dart';

import '../tokens/pp_forge_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/app_button.dart';
import '../tokens/button_icon_kind.dart';

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
          PpForgeSpacing.lg,
          PpForgeSpacing.sm,
          PpForgeSpacing.lg,
          PpForgeSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: PpForgeButton(
                label: cancelLabel,
                kind: ButtonIconKind.cancel,
                variant: PpForgeButtonVariant.outlined,
                size: PpForgeButtonSize.large,
                expand: true,
                onPressed: saving ? null : onCancel,
              ),
            ),
            if (onUndo != null) ...[
              const SizedBox(width: PpForgeSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: canUndo && !saving
                    ? PpForgeIconButton(
                        key: const ValueKey('undo-on'),
                        tooltip: undoTooltip,
                        onPressed: onUndo,
                        icon: PpForgeIcons.undo,
                      )
                    : SizedBox.square(
                        key: const ValueKey('undo-off'),
                        dimension: PpForgeIconButton.resolveSize(context),
                      ),
              ),
            ],
            const SizedBox(width: PpForgeSpacing.sm),
            Expanded(
              child: PpForgeButton(
                label: saveLabel,
                kind: ButtonIconKind.save,
                size: PpForgeButtonSize.large,
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
