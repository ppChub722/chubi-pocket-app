import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/connection_cubit.dart';
import '../features/app_version/presentation/widgets/update_banner.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../ui/ui.dart';

class ConnectionShell extends StatelessWidget {
  const ConnectionShell({
    required this.child,
    this.devHub = false,
    this.hideConnectionSnack = false,
    super.key,
  });

  final Widget child;

  /// Auth pages: the connection snack reads as online (offline there shows
  /// only the failed submit's snack). Offline gating stays on.
  final bool hideConnectionSnack;

  /// On the dev hub (isDevHubPath): no connection snack / update banner and
  /// no offline gating, so the widgets work without a backend.
  final bool devHub;

  @override
  Widget build(BuildContext context) {
    final coldStart = context.select<AuthCubit, bool>(
      (c) => c.state is AuthInitial,
    );
    return BlocBuilder<ConnectionCubit, ServerConnectionState>(
      builder: (context, conn) {
        final quiet = coldStart || devHub || hideConnectionSnack;
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
              // Draws nothing: keeps the connection snack on the bottom
              // SnackStack (it reads as online on cold start, on the dev hub
              // and on auth pages).
              ConnectionSnack(
                state: conn,
                quiet: quiet,
                onRetry: context.read<ConnectionCubit>().retryNow,
              ),
            ],
          ),
        );
      },
    );
  }
}
