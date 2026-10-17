import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../ui/ui.dart';

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
