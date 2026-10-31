import 'dart:async';

import 'package:flutter/material.dart';

import '../atoms/ui_config.dart';
import '../tokens/tone.dart';
import 'snack_stack.dart';

/// A failure snack that only says "no connection" / "slow" while the
/// connection snack already says it: offline shows that one snack only.
bool _saidByConnectionSnack(BuildContext context, String message, Tone tone) {
  if (tone != Tone.danger || !SnackStack.connectionCovers) return false;
  final errors = UiConfig.of(context).errors;
  for (final e in [TimeoutException('offline'), TimeoutException('slow')]) {
    final info = errors.describe(e);
    if (message.contains(info.message) || message.contains(info.title)) {
      return true;
    }
  }
  return false;
}

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
  if (_saidByConnectionSnack(context, message, tone)) return;
  if (ModalRoute.of(context) is PopupRoute) {
    final overlay = Overlay.maybeOf(context);
    if (overlay != null) {
      SnackStack.over(
        overlay,
      ).show(message, tone: tone, actionLabel: actionLabel, onAction: onAction);
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
}) {
  if (_saidByConnectionSnack(messenger.context, message, tone)) return;
  SnackStack.of(
    messenger,
  ).show(message, tone: tone, actionLabel: actionLabel, onAction: onAction);
}
