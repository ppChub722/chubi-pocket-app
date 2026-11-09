import 'package:flutter/material.dart';

import '../atoms/ui_config.dart';
import '../tokens/tone.dart';
import 'app_snackbar.dart';
import 'error_view.dart';

void showErrorSnackBar(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) {
  showPpForgeSnackBar(
    context,
    ErrorView.titleFor(context, error),
    tone: Tone.danger,
    actionLabel: onRetry == null ? null : PpForgeConfig.stringsOf(context).retry,
    onAction: onRetry,
  );
}

void showErrorSnackBarOn(
  ScaffoldMessengerState messenger,
  Object error, {
  VoidCallback? onRetry,
}) {
  final context = messenger.context;
  showPpForgeSnackBarOn(
    messenger,
    ErrorView.titleFor(context, error),
    tone: Tone.danger,
    actionLabel: onRetry == null ? null : PpForgeConfig.stringsOf(context).retry,
    onAction: onRetry,
  );
}
