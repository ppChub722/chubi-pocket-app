import 'package:flutter/material.dart';

import '../../../core/network/connection_cubit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../molecules/connection_banner.dart';
import '../../molecules/snack_stack.dart';

/// The connection state as one message (connecting… n/N, can't connect +
/// Retry, back online); the content of the connection snack.
class ConnectionSnackMessage extends StatelessWidget {
  const ConnectionSnackMessage({
    required this.state,
    this.onRetry,
    this.onClose,
    super.key,
  });

  final ServerConnectionState state;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConnectionBanner(
      state: switch (state.status) {
        ConnectionStatus.reconnecting => ConnectionBannerState.reconnecting,
        ConnectionStatus.backOnline => ConnectionBannerState.backOnline,
        _ => ConnectionBannerState.offline,
      },
      offlineText: l.connectionCantConnect,
      // "connecting… n/N" once a retry runs (the cubit's policy).
      reconnectingText: state.attempt > 0 && state.attempts > 0
          ? l.connectionConnectingAttempt(state.attempt, state.attempts)
          : l.connectionReconnecting,
      backText: l.connectionBack,
      retryLabel: l.connectionRetry,
      onRetry: onRetry,
      onClose: onClose,
    );
  }
}

/// Keeps the app-wide connection snack on the SnackStack in line with
/// [state] (it draws nothing itself). The snack sits at the bottom with the
/// others and stays while the connection is not online; its X only hides it
/// (offline gating stays, nothing is sent), and it shows again when the
/// status changes or a new cycle starts (a fresh "connecting…", a new
/// failure). [quiet] (cold start, dev hub, auth pages) reads as online.
class ConnectionSnack extends StatefulWidget {
  const ConnectionSnack({
    required this.state,
    this.quiet = false,
    this.onRetry,
    super.key,
  });

  static const stackKey = 'connection';

  final ServerConnectionState state;
  final bool quiet;
  final VoidCallback? onRetry;

  static bool visible(ServerConnectionState s) =>
      s.status != ConnectionStatus.online;

  @override
  State<ConnectionSnack> createState() => _ConnectionSnackState();
}

class _ConnectionSnackState extends State<ConnectionSnack> {
  /// The state the user closed the snack on; null = not closed.
  ServerConnectionState? _closedOn;
  SnackStack? _stack;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stack = SnackStack.of(ScaffoldMessenger.of(context));
    if (_stack != stack) {
      _stack?.clearSticky(ConnectionSnack.stackKey);
      _stack = stack;
    }
    _sync();
  }

  @override
  void didUpdateWidget(ConnectionSnack old) {
    super.didUpdateWidget(old);
    if (_closedOn != null && !_closed) _closedOn = null;
    _sync();
  }

  void _sync() {
    final stack = _stack;
    if (stack == null) return;
    // After the frame: the stack's view must not rebuild during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _stack != stack) return;
      final show =
          !widget.quiet && ConnectionSnack.visible(widget.state) && !_closed;
      if (!show) {
        stack.clearSticky(ConnectionSnack.stackKey);
        return;
      }
      final state = widget.state;
      stack.setSticky(
        ConnectionSnack.stackKey,
        (context) => ConnectionSnackMessage(
          state: state,
          onRetry: widget.onRetry,
          onClose: () {
            setState(() => _closedOn = state);
            _sync();
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _stack?.clearSticky(ConnectionSnack.stackKey, show: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
