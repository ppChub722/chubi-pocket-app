import 'package:flutter/material.dart';

import '../tokens/tone.dart';
import 'app_message.dart';

/// Which state the [ConnectionBanner] shows.
enum ConnectionBannerState {
  /// Cannot reach the server; retrying by itself. Stays until it is back.
  offline,

  /// A retry is running right now.
  reconnecting,

  /// Back — a short "connected again" message.
  backOnline,
}

/// The persistent server-connection banner at the top of every page (owner
/// 2026-10-12): an [AppMessage] banner that never auto-dismisses while the
/// connection is down — "can't reach the server · trying again…" with a retry
/// button, then a short "connected again". The strings are the page's / app's.
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

  /// Retry now (the offline state's action).
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
