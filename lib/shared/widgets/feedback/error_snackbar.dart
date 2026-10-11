import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../chips/tone.dart';
import '../error_view.dart';
import 'app_snackbar.dart';

/// A failure while data is on screen, or a failed save / delete / action:
/// stay on the page (never replace it with an error page — the user would
/// lose their edits) and show a danger snackbar with a "ลองอีกครั้ง" action.
///
/// [error] may be an [ApiException] (localised by its kind: network /
/// server / unknown) or anything else (unknown). Omit [onRetry] to show the
/// message without the action. A load failure with NO data on screen is the
/// full-page [ErrorView] instead (see `AsyncStateView`).
void showErrorSnackBar(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) {
  final l = AppLocalizations.of(context)!;
  final e = error is ApiException
      ? error
      : const ApiException(code: 'UNKNOWN', message: 'unknown');
  showAppSnackBar(
    context,
    ErrorView.titleFor(l, e),
    tone: Tone.danger,
    actionLabel: onRetry == null ? null : l.commonRetry,
    onAction: onRetry,
  );
}
