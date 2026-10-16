import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';
import '../molecules/confirm_dialog.dart';
import '../organisms/app_sheet.dart';
import '../organisms/saving_overlay.dart';
import '../tokens/app_spacing.dart';

/// THE form sheet (owner 2026-10-12): a bottom sheet that edits something
/// and ends with Cancel · Save. Open it with `showPpForgeSheetCustom` and return
/// a `FormSheet` from the builder:
///
/// ```dart
/// showPpForgeSheetCustom<Result>(context, builder: (ctx) => FormSheet(
///   title: 'Adjust balance',
///   primaryLabel: 'Adjust',
///   onPrimary: canSave ? () => Navigator.pop(ctx, result) : null,
///   child: Column(children: [...fields]),
/// ));
/// ```
///
/// What it owns, so no sheet re-invents it:
/// - the chrome (drag handle, title, scrolling body, keyboard padding —
///   [PpForgeSheetScaffold]) and the pinned footer: a Cancel button + the primary
///   action, both large;
/// - [saving]: a dim overlay + spinner while the call runs, the buttons and
///   back disabled (see [SavingOverlay]);
/// - [dirty]: closing a changed form (back, swipe, Cancel) asks "Discard your
///   changes?" first; a clean one just closes;
/// - [destructive]: the primary button in the error colour (a delete form).
///
/// A failed save stays on the sheet (never lose what was typed): the caller
/// sets [saving] back to false and shows `showErrorSnackBar` with a retry.
class FormSheet extends StatelessWidget {
  const FormSheet({
    required this.title,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.cancelLabel,
    this.showCancel = true,
    this.saving = false,
    this.dirty = false,
    this.destructive = false,
    super.key,
  });

  final String title;
  final Widget child;

  /// The main action's label ("Save", "Adjust", "Invite").
  final String primaryLabel;

  /// Null = disabled (nothing valid to save yet).
  final VoidCallback? onPrimary;

  /// Defaults to the app's "Cancel".
  final String? cancelLabel;

  /// False = only the primary button.
  final bool showCancel;
  final bool saving;
  final bool dirty;
  final bool destructive;

  Future<void> _close(BuildContext context) async {
    if (!dirty) {
      Navigator.of(context).maybePop();
      return;
    }
    final s = PpForgeConfig.stringsOf(context);
    final discard = await showConfirmDialog(
      context,
      title: s.discardTitle,
      message: s.discardMessage,
      confirmLabel: s.discardConfirm,
      cancelLabel: s.keepEditing,
      destructive: true,
    );
    if (discard && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = PpForgeConfig.stringsOf(context);
    return PopScope(
      // Back / swipe on a changed form goes through the question.
      canPop: !dirty || saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      child: SavingOverlay(
        saving: saving,
        child: PpForgeSheetScaffold(
          title: title,
          footer: Row(
            children: [
              if (showCancel) ...[
                Expanded(
                  child: PpForgeButton(
                    label: cancelLabel ?? s.cancel,
                    variant: PpForgeButtonVariant.outlined,
                    size: PpForgeButtonSize.large,
                    expand: true,
                    onPressed: saving ? null : () => _close(context),
                  ),
                ),
                const SizedBox(width: PpForgeSpacing.md),
              ],
              Expanded(
                child: PpForgeButton(
                  label: primaryLabel,
                  variant: destructive
                      ? PpForgeButtonVariant.destructive
                      : PpForgeButtonVariant.primary,
                  size: PpForgeButtonSize.large,
                  expand: true,
                  // Offline: a save can't reach the server, so the button
                  // disables itself (the banner says why); typed input stays.
                  submits: true,
                  onPressed: saving ? null : onPrimary,
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
