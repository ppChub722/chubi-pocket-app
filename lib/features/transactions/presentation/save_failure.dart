import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../ui/ui.dart';

/// A save / delete that failed — the page stays as it is (nothing typed is
/// lost) and says so in a snackbar.
///
/// A transport or server failure (no status, or 5xx) is worth another go:
/// [showErrorSnackBar] with a "ลองอีกครั้ง" action running [retry]. A
/// rejection from the BE (4xx — a wallet that can't go negative, a split
/// that doesn't add up) says its own [message] (else the BE's text) with no
/// retry: sending the same thing again can't help.
void showSaveFailure(
  BuildContext context,
  ApiException e, {
  required VoidCallback retry,
  String? message,
}) {
  final status = e.statusCode;
  if (status == null || status >= 500) {
    showErrorSnackBar(context, e, onRetry: retry);
    return;
  }
  showAppSnackBar(context, message ?? e.message, tone: Tone.danger);
}
