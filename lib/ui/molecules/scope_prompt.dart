import 'package:flutter/widgets.dart';

import '../atoms/app_button.dart';
import '../organisms/edit_scope_choice.dart';
import 'choice_dialog.dart';

/// "Apply the change to…" for a recurring series (a budget's new setup, owner
/// 2026-10-13), as a dialog like `showLinkedPrompt`:
///
///   [ยังก่อน]  [รอบนี้และถัดไป]  [ทุกรอบ]
///
/// Every word comes in as a param. Resolves [EditScope.following] or
/// [EditScope.all], or null for [cancelLabel] / back / the barrier (nothing
/// is saved, typed input stays). [destructive]: the "all" button is red.
Future<EditScope?> showScopePrompt(
  BuildContext context, {
  required String title,
  required String cancelLabel,
  required String followingLabel,
  required String allLabel,
  String? message,
  bool destructive = false,
}) => showChoiceDialog<EditScope?>(
  context,
  title: title,
  message: message,
  choices: [
    DialogChoice(
      value: null,
      label: cancelLabel,
      variant: PpForgeButtonVariant.text,
    ),
    DialogChoice(
      value: EditScope.following,
      label: followingLabel,
      variant: PpForgeButtonVariant.outlined,
    ),
    DialogChoice(
      value: EditScope.all,
      label: allLabel,
      variant: destructive
          ? PpForgeButtonVariant.destructive
          : PpForgeButtonVariant.primary,
    ),
  ],
);
