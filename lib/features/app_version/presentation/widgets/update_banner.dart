import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../cubit/app_version_cubit.dart';
import '../pages/update_required_page.dart';
import '../../../../ui/ui.dart';

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
      duration: AppDurations.fast,
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
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: AppMessage(
          message: l.appUpdateAvailable,
          actions: [
            AppMessageAction(
              label: l.appUpdateAvailableAction,
              onPressed: onUpdate,
            ),
          ],
          onClose: onDismiss,
        ),
      ),
    );
  }
}
