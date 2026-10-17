import 'package:flutter/material.dart';

import '../atoms/ui_config.dart';
import '../tokens/tone.dart';
import 'app_snackbar.dart';
import 'error_view.dart';

/// A failure while data is on screen, or a failed save / delete / action:
/// stay on the page (never replace it with an error page — the user would
/// lose their edits) and show a danger snackbar with a retry action.
///
/// [error] is anything the app's [UiErrors] can describe (network / server /
/// unexpected). Omit [onRetry] to show the message without the action. A
/// load failure with NO data on screen is the full-page [ErrorView] instead
/// (see `AsyncStateView`).
void showErrorSnackBar(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) {
  showAppSnackBar(
    context,
    ErrorView.titleFor(context, error),
    tone: Tone.danger,
    actionLabel: onRetry == null ? null : UiConfig.stringsOf(context).retry,
    onAction: onRetry,
  );
}

/// [showErrorSnackBar] through a page's own [messenger] (edit-mode pages: it
/// floats above their save bar).
void showErrorSnackBarOn(
  ScaffoldMessengerState messenger,
  Object error, {
  VoidCallback? onRetry,
}) {
  final context = messenger.context;
  showAppSnackBarOn(
    messenger,
    ErrorView.titleFor(context, error),
    tone: Tone.danger,
    actionLabel: onRetry == null ? null : UiConfig.stringsOf(context).retry,
    onAction: onRetry,
  );
}
