import 'package:flutter/material.dart';

import '../../../core/network/connection_cubit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../molecules/connection_banner.dart';
import '../../tokens/app_spacing.dart';

/// The server-connection banner at the top of every page (owner 2026-10-12,
/// offline mode): the kit's [ConnectionBanner] with the app's words. Nothing
/// while online; "can't reach the server · trying again…" + Retry while the
/// server is unreachable (it stays until the connection is back, never
/// auto-dismisses); a short "connected again" when it returns. Slides in /
/// out; the status-bar inset moves into it while shown. Wired globally via
/// `MaterialApp.router`'s `builder:` from `ConnectionCubit`.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.state, this.onRetry, super.key});

  final ServerConnectionState state;

  /// Retry now (the banner's button).
  final VoidCallback? onRetry;

  /// Whether the banner takes space (the page below drops its own top inset).
  static bool visible(ServerConnectionState s) =>
      s.status != ConnectionStatus.online;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: !visible(state)
          ? const SizedBox(width: double.infinity)
          : SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PpForgeSpacing.md,
                  PpForgeSpacing.xs,
                  PpForgeSpacing.md,
                  PpForgeSpacing.xs,
                ),
                child: ConnectionBanner(
                  state: switch (state.status) {
                    ConnectionStatus.reconnecting =>
                      ConnectionBannerState.reconnecting,
                    ConnectionStatus.backOnline =>
                      ConnectionBannerState.backOnline,
                    _ => ConnectionBannerState.offline,
                  },
                  offlineText: l.connectionOffline,
                  reconnectingText: l.connectionReconnecting,
                  backText: l.connectionBack,
                  retryLabel: l.connectionRetry,
                  onRetry: onRetry,
                ),
              ),
            ),
    );
  }
}
