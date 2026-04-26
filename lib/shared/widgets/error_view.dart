import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shown when an async call fails.
///
/// Per design-sheet §8.5: 3 message variants depending on the [ApiException]
/// code — network / server / unknown. Pass [onRetry] to render the Retry CTA.
///
/// ```dart
/// BlocBuilder<AccountsCubit, AccountsState>(
///   builder: (context, state) => switch (state) {
///     AccountsError(:final error) => ErrorView(
///       error: error,
///       onRetry: () => context.read<AccountsCubit>().load(),
///     ),
///     ...
///   },
/// );
/// ```
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final ApiException error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final variant = _variantFor(error);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(variant.icon, size: 64, color: scheme.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _titleFor(l, variant),
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _messageFor(l, variant),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l.commonRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _ErrorVariant { network, server, unknown }

_ErrorVariant _variantFor(ApiException e) {
  if (e.code == 'NETWORK_ERROR' || e.code == 'NETWORK_TIMEOUT') {
    return _ErrorVariant.network;
  }
  final status = e.statusCode;
  if (status != null && status >= 500) return _ErrorVariant.server;
  return _ErrorVariant.unknown;
}

extension _ErrorVariantIcon on _ErrorVariant {
  IconData get icon => switch (this) {
        _ErrorVariant.network => Icons.wifi_off_outlined,
        _ErrorVariant.server => Icons.cloud_off_outlined,
        _ErrorVariant.unknown => Icons.error_outline,
      };
}

String _titleFor(AppLocalizations l, _ErrorVariant v) => switch (v) {
      _ErrorVariant.network => l.errorNetworkTitle,
      _ErrorVariant.server => l.errorServerTitle,
      _ErrorVariant.unknown => l.errorUnknownTitle,
    };

String _messageFor(AppLocalizations l, _ErrorVariant v) => switch (v) {
      _ErrorVariant.network => l.errorNetworkMessage,
      _ErrorVariant.server => l.errorServerMessage,
      _ErrorVariant.unknown => l.errorUnknownMessage,
    };
