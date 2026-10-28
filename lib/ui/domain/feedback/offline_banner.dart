import 'package:flutter/material.dart';

import '../../../core/network/connection_cubit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../molecules/connection_banner.dart';
import '../../tokens/app_spacing.dart';

/// The app-wide connection banner. Its X only hides it (offline gating
/// stays, nothing is sent); it shows again when the status changes or a new
/// cycle starts (a fresh "connecting…", a new failure).
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({required this.state, this.onRetry, super.key});

  final ServerConnectionState state;

  final VoidCallback? onRetry;

  static bool visible(ServerConnectionState s) =>
      s.status != ConnectionStatus.online;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  /// The state the user closed the banner on; null = not closed.
  ServerConnectionState? _closedOn;

  bool get _closed {
    final closed = _closedOn;
    if (closed == null) return false;
    final now = widget.state;
    // Retry progress within the same cycle stays hidden; a new status or a
    // new cycle (the attempt count starts over) brings it back.
    return now.status == closed.status &&
        now.attempt >= closed.attempt &&
        now.reconnects == closed.reconnects;
  }

  @override
  void didUpdateWidget(OfflineBanner old) {
    super.didUpdateWidget(old);
    if (_closedOn != null && !_closed) _closedOn = null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = widget.state;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: !OfflineBanner.visible(state) || _closed
          ? const SizedBox(width: double.infinity)
          : SafeArea(
              bottom: false,
              child: Padding(
                // The kit gap all round: the banner never touches the page.
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: ConnectionBanner(
                  state: switch (state.status) {
                    ConnectionStatus.reconnecting =>
                      ConnectionBannerState.reconnecting,
                    ConnectionStatus.backOnline =>
                      ConnectionBannerState.backOnline,
                    _ => ConnectionBannerState.offline,
                  },
                  offlineText: l.connectionCantConnect,
                  // "connecting… n/N" once a retry runs (the cubit's policy).
                  reconnectingText: state.attempt > 0 && state.attempts > 0
                      ? l.connectionConnectingAttempt(
                          state.attempt,
                          state.attempts,
                        )
                      : l.connectionReconnecting,
                  backText: l.connectionBack,
                  retryLabel: l.connectionRetry,
                  onRetry: widget.onRetry,
                  onClose: () => setState(() => _closedOn = state),
                ),
              ),
            ),
    );
  }
}
