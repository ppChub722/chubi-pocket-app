import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../cubit/app_version_cubit.dart';
import '../pages/update_required_page.dart';

/// "มีเวอร์ชันใหม่" — a strip over every screen (next to the offline
/// banner) while a newer build is out but this one still works. Closing
/// it keeps it away for a day.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AppVersionCubit?>();
    final state = cubit?.state;
    final show = state != null && state.showBanner;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: show
          ? UpdateBannerStrip(
              onUpdate: () => openAppDownload(context, state.info.downloadUrl),
              onDismiss: cubit!.dismissBanner,
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

/// The strip itself (gallery, tests).
class UpdateBannerStrip extends StatelessWidget {
  const UpdateBannerStrip({
    required this.onUpdate,
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.appUpdateAvailable,
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
              TextButton(
                onPressed: onUpdate,
                child: Text(l.appUpdateAvailableAction),
              ),
              IconButton(
                tooltip: l.appUpdateLater,
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: scheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
