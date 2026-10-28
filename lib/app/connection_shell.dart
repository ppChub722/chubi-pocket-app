import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/connection_cubit.dart';
import '../features/app_version/presentation/widgets/update_banner.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../ui/ui.dart';

class ConnectionShell extends StatelessWidget {
  const ConnectionShell({required this.child, this.devHub = false, super.key});

  final Widget child;

  /// On the dev hub (isDevHubPath): no offline / update banner and no
  /// offline gating, so the widgets work without a backend.
  final bool devHub;

  @override
  Widget build(BuildContext context) {
    final coldStart = context.select<AuthCubit, bool>(
      (c) => c.state is AuthInitial,
    );
    return BlocBuilder<ConnectionCubit, ServerConnectionState>(
      builder: (context, conn) {
        final quiet = coldStart || devHub;
        return ConnectionScope(
          offline: !devHub && conn.isOffline,
          reconnects: conn.reconnects,
          child: Stack(
            children: [
              Column(
                children: [
                  if (devHub)
                    const SizedBox(width: double.infinity)
                  else
                    const UpdateBanner(),
                  Expanded(child: child),
                ],
              ),
              // Always in the tree (a child appearing above would remount every
              // page below); it just reads as online on cold start and on the
              // dev hub.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OfflineBanner(
                  state: quiet ? const ServerConnectionState() : conn,
                  onRetry: context.read<ConnectionCubit>().retryNow,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
