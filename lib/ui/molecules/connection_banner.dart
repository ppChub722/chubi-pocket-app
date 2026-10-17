import 'package:flutter/material.dart';

import '../tokens/tone.dart';
import 'app_message.dart';

enum ConnectionBannerState {
  /// Cannot reach the server; retrying by itself.
  offline,

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
    super.key,
  });

  final ConnectionBannerState state;
  final String offlineText;
  final String reconnectingText;
  final String backText;
  final String retryLabel;

  final VoidCallback? onRetry;

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
      ),
      ConnectionBannerState.reconnecting => AppMessage(
        tone: Tone.warning,
        message: reconnectingText,
      ),
      ConnectionBannerState.backOnline => AppMessage(
        tone: Tone.success,
        message: backText,
      ),
    };
  }
}
