import 'package:flutter/material.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../users/presentation/refresh_me.dart';
import '../widgets/auto_sync_setting.dart';

/// Settings › ซิงก์อัตโนมัติ: the two switches (separate from muting a
/// notification: a muted type still syncs quietly).
class SettingsSyncPage extends StatelessWidget {
  const SettingsSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final inset = MediaQuery.paddingOf(context);
    return Scaffold(
      appBar: AppTopBar(title: l.settingsGroupSync, showBack: true),
      extendBodyBehindAppBar: true,
      body: DetailPageBody(
        onRefresh: () => refreshMe(context),
        topInset: inset.top + AppSpacing.lg,
        bottomInset: AppSpacing.huge + inset.bottom,
        sections: [
          // A NEW bill first (owner 2026-10-28), then later edits.
          (first) => SectionCard(
            first: first,
            title: l.settingsAcceptTitle,
            description: l.settingsAcceptLegend,
            children: const [
              AutoSyncSetting(
                kind: AutoSyncKind.events,
                which: AutoSyncSwitch.accept,
              ),
              AutoSyncSetting(
                kind: AutoSyncKind.debts,
                which: AutoSyncSwitch.accept,
              ),
            ],
          ),
          (first) => SectionCard(
            first: first,
            title: l.settingsGroupSync,
            description: l.settingsSyncLegend,
            children: const [
              AutoSyncSetting(kind: AutoSyncKind.events),
              AutoSyncSetting(kind: AutoSyncKind.debts),
            ],
          ),
        ],
        // The page's footnote: where else the switches live.
        metaLines: [l.settingsSyncFootnote],
      ),
    );
  }
}
