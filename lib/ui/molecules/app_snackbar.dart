import 'package:flutter/material.dart';

import '../tokens/tone.dart';
import 'snack_stack.dart';

/// Shows a snack on the SnackStack: bottom only, newer ones push the older
/// ones up (see SnackStack). Over a sheet (no Scaffold) it stacks above the
/// sheet.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Tone tone = Tone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (ModalRoute.of(context) is PopupRoute) {
    final overlay = Overlay.maybeOf(context);
    if (overlay != null) {
      SnackStack.over(overlay).show(
        message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
      );
      return;
    }
  }
  showAppSnackBarOn(
    ScaffoldMessenger.of(context),
    message,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  Tone tone = Tone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) => SnackStack.of(
  messenger,
).show(message, tone: tone, actionLabel: actionLabel, onAction: onAction);

