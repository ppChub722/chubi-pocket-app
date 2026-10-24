import 'package:flutter/material.dart';

import '../../../../app/shell/tab_root_scaffold.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';

/// The home tab while the dashboard is reworked (owner 2026-10-24): no API
/// call on open. The full dashboard stays in home_page.dart for later.
class HomeComingSoonPage extends StatelessWidget {
  const HomeComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return TabRootScaffold(
      title: l.navDashboard,
      body: EmptyView(
        icon: AppIcons.hourglass,
        title: l.homeComingSoonTitle,
        message: l.homeComingSoonMessage,
      ),
    );
  }
}
