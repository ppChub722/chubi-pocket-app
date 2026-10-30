import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';
import '../molecules/confirm_dialog.dart';
import '../organisms/app_sheet.dart';
import '../atoms/busy_scope.dart';
import '../tokens/app_spacing.dart';

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

  final String primaryLabel;

  final VoidCallback? onPrimary;

  final String? cancelLabel;

  final bool showCancel;
  final bool saving;
  final bool dirty;
  final bool destructive;

  Future<void> _close(BuildContext context) async {
    if (!dirty) {
      Navigator.of(context).maybePop();
      return;
    }
    final s = UiConfig.stringsOf(context);
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
    final s = UiConfig.stringsOf(context);
    return PopScope(
      canPop: !dirty || saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      child: BusyScope(
        busy: saving,
        child: AppSheetScaffold(
          title: title,
          footer: Row(
            children: [
              if (showCancel) ...[
                Expanded(
                  child: AppButton(
                    label: cancelLabel ?? s.cancel,
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: saving ? null : () => _close(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: AppButton(
                  label: primaryLabel,
                  variant: destructive
                      ? AppButtonVariant.destructive
                      : AppButtonVariant.primary,
                  size: AppButtonSize.large,
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
