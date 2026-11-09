import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';
import '../molecules/confirm_dialog.dart';
import '../organisms/app_sheet.dart';
import '../atoms/busy_scope.dart';
import '../tokens/app_spacing.dart';
import '../tokens/button_icon_kind.dart';

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
    this.primaryKind,
    super.key,
  });

  final String title;
  final Widget child;

  final String primaryLabel;

  final VoidCallback? onPrimary;

  final String? cancelLabel;

  final bool showCancel;
  final bool saving;
  final bool dirty;
  final bool destructive;

  /// Null = delete when [destructive], save otherwise.
  final ButtonIconKind? primaryKind;

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
      canPop: !dirty || saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      child: BusyScope(
        busy: saving,
        child: PpForgeSheetScaffold(
          title: title,
          footer: Row(
            children: [
              if (showCancel) ...[
                Expanded(
                  child: PpForgeButton(
                    label: cancelLabel ?? s.cancel,
                    kind: ButtonIconKind.cancel,
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
                  kind:
                      primaryKind ??
                      (destructive
                          ? ButtonIconKind.delete
                          : ButtonIconKind.save),
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
