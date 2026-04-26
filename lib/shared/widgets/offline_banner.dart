import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/network/connectivity_cubit.dart';
import '../../l10n/gen/app_localizations.dart';

/// Top-of-screen banner shown when the device has no network. Auto-dismisses
/// when connectivity returns. Wired globally via [MaterialApp.router]'s
/// `builder:` so every page picks it up.
///
/// Per design-sheet §8.5: 48 dp tall, surface-container background, slides in
/// from top in 200 ms.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, isOnline) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: isOnline ? const SizedBox.shrink() : const _Banner(),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 48,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(Icons.wifi_off, size: 16, color: scheme.onSurface),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  // l can be null very briefly during the first frame before
                  // localizations resolve; fall back to the English string.
                  l?.offlineBanner ?? "You're offline",
                  style: TextStyle(color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
