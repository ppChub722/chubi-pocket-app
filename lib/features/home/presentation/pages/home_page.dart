import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';

/// Phase 0 dashboard — demonstrates the [EmptyView] state-pattern widget.
///
/// Phase 1a replaces this with the real dashboard (account cards row, summary
/// card, recent transactions). The chrome (top bar + bottom nav + center FAB)
/// is owned by the shell and is NOT re-declared here.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EmptyView(
      icon: Icons.savings_outlined,
      title: l.homeEmptyTitle,
      message: l.homeEmptyMessage,
    );
  }
}
