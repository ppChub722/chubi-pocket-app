import 'package:flutter/material.dart';

import '../tokens/tone.dart';
import 'app_message.dart';

enum ConnectionBannerState {
  /// Could not reach the server and stopped trying: a retry button.
  offline,

  /// Trying to reach the server (a spinner, no error, no button).
  reconnecting,

  backOnline,
}

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    required this.state,
    required this.offlineText,
    required this.reconnectingText,
    required this.backText,
    required this.retryLabel,
    this.onRetry,
    this.onClose,
    super.key,
  });

  final ConnectionBannerState state;
  final String offlineText;
  final String reconnectingText;
  final String backText;
  final String retryLabel;

  final VoidCallback? onRetry;

  /// A plain X after the action: hides the banner only (the caller decides
  /// when it comes back). Not on "back online" (it goes by itself).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ConnectionBannerState.offline => AppMessage(
        tone: Tone.danger,
        message: offlineText,
        actions: [
          if (onRetry != null)
            AppMessageAction(label: retryLabel, onPressed: onRetry!),
        ],
        onClose: onClose,
      ),
      ConnectionBannerState.reconnecting => AppMessage(
        tone: Tone.info,
        busy: true,
        message: reconnectingText,
        onClose: onClose,
      ),
      ConnectionBannerState.backOnline => AppMessage(
        tone: Tone.success,
        message: backText,
      ),
    };
  }
}
