import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/app_version_info.dart';
import '../cubit/app_version_cubit.dart';

/// Opens the new build's download page outside the app; a snackbar when
/// it can't.
Future<void> openAppDownload(BuildContext context, String url) async {
  final l = AppLocalizations.of(context)!;
  final uri = Uri.tryParse(url);
  final ok =
      uri != null &&
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).catchError((_) => false);
  if (!ok && context.mounted) {
    showAppSnackBar(context, l.appUpdateOpenFailed, tone: Tone.danger);
  }
}

/// `/update-required` — the version gate's wall (owner 2026-10-10): this
/// build is below the server's minimum. Logo, why, and one way out: the
/// download. Nothing gets past it; back closes the app. The router keeps
/// every route but `/dev/*` here while the gate is shut.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppVersionCubit>().state;
    return UpdateRequiredView(info: state.info, currentBuild: state.build);
  }
}

/// The page's look, from plain values (gallery, tests).
class UpdateRequiredView extends StatelessWidget {
  const UpdateRequiredView({
    required this.info,
    this.currentBuild,
    this.exitOnBack = true,
    super.key,
  });

  final AppVersionInfo info;

  /// This app's build, when known.
  final int? currentBuild;

  /// Back closes the app (the real gate). False for a preview (gallery).
  final bool exitOnBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final message =
        info.messageFor(Localizations.localeOf(context)) ??
        l.appUpdateRequiredBody;
    final hasLink = info.downloadUrl.isNotEmpty;
    return PopScope(
      canPop: !exitOnBack,
      // No way past it — back leaves the app.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l.appUpdateRequiredTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (currentBuild != null && info.minBuild > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l.appUpdateBuildLine(currentBuild!, info.minBuild),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: l.appUpdateDownload,
                    icon: Icons.download_rounded,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: hasLink
                        ? () => openAppDownload(context, info.downloadUrl)
                        : null,
                  ),
                  if (!hasLink) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l.appUpdateNoLink,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
