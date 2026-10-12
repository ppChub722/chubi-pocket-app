import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/connection_cubit.dart';
import '../features/app_version/presentation/widgets/update_banner.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../ui/ui.dart';

/// The app-wide offline wiring (owner 2026-10-12, offline mode), installed once
/// around every page and sheet by `MaterialApp.router`'s `builder:`:
///
/// - [ConnectionScope] from [ConnectionCubit], so the kit disables submits,
///   errors no-data pages at once and reloads pages when the server is back;
/// - the [OfflineBanner] on top (offline + Retry, then a short "connected
///   again"), with the [UpdateBanner] under it;
/// - while the banner shows it holds the status-bar inset, so the page below
///   gets its top padding removed (no double gap).
///
/// Cold start (auth still resolving, the splash on screen) has no banner: the
/// splash's own full-screen error + retry says it, and it retries by itself
/// when the connection comes back.
class ConnectionShell extends StatelessWidget {
  const ConnectionShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final coldStart = context.select<AuthCubit, bool>(
      (c) => c.state is AuthInitial,
    );
    return BlocBuilder<ConnectionCubit, ServerConnectionState>(
      builder: (context, conn) {
        final banner = !coldStart && OfflineBanner.visible(conn);
        return ConnectionScope(
          offline: conn.isOffline,
          reconnects: conn.reconnects,
          child: Column(
            children: [
              // Always in the tree (a child appearing above would remount
              // every page below); it just reads as online on cold start.
              OfflineBanner(
                state: coldStart ? const ServerConnectionState() : conn,
                onRetry: context.read<ConnectionCubit>().retryNow,
              ),
              const UpdateBanner(),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: banner,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
