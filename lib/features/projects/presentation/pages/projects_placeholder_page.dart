import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';

/// Phase 0 placeholder for the Projects tab.
///
/// Real project list (trips, freelance books, shared expenses) ships in
/// Phase 1b.
class ProjectsPlaceholderPage extends StatelessWidget {
  const ProjectsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EmptyView(
      icon: Icons.groups_outlined,
      title: l.projectsPlaceholderTitle,
      message: l.projectsPlaceholderMessage,
    );
  }
}
