import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';

/// Bottom sheet shown when the user taps `More` on the bottom nav.
///
/// Lists features that don't have a primary tab. Phase 0 ships every entry as
/// "Coming soon" — they activate as their phases land:
/// - **Phase 1a** — Transactions (full list), Categories, Tags
/// - **Phase 1b** — Contacts, Debts, Notifications
/// - **Phase 1c** — Budgets, Saving goals, Scheduled
///
/// Profile / Settings / Logout intentionally do NOT live here — they live
/// behind the avatar tap in the top bar (`/settings`).
class MoreMenuSheet extends StatelessWidget {
  const MoreMenuSheet({super.key});

  /// Shows the sheet over the active shell tab. Returns when dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const MoreMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(text: l.morePhase1aHeader),
            _MoreItem(
              icon: Icons.list_alt_outlined,
              title: l.moreTransactions,
              comingSoonMessage: l.moreComingInPhase1a,
            ),
            _MoreItem(
              icon: Icons.category_outlined,
              title: l.moreCategories,
              comingSoonMessage: l.moreComingInPhase1a,
            ),
            _MoreItem(
              icon: Icons.sell_outlined,
              title: l.moreTags,
              comingSoonMessage: l.moreComingInPhase1a,
            ),
            _SectionHeader(text: l.morePhase1bHeader),
            _MoreItem(
              icon: Icons.contacts_outlined,
              title: l.moreContacts,
              comingSoonMessage: l.moreComingInPhase1b,
            ),
            _MoreItem(
              icon: Icons.account_balance_outlined,
              title: l.moreDebts,
              comingSoonMessage: l.moreComingInPhase1b,
            ),
            _MoreItem(
              icon: Icons.notifications_outlined,
              title: l.moreNotifications,
              comingSoonMessage: l.moreComingInPhase1b,
            ),
            _SectionHeader(text: l.morePhase1cHeader),
            _MoreItem(
              icon: Icons.savings_outlined,
              title: l.moreBudgets,
              comingSoonMessage: l.moreComingInPhase1c,
            ),
            _MoreItem(
              icon: Icons.flag_outlined,
              title: l.moreSavingGoals,
              comingSoonMessage: l.moreComingInPhase1c,
            ),
            _MoreItem(
              icon: Icons.schedule_outlined,
              title: l.moreScheduled,
              comingSoonMessage: l.moreComingInPhase1c,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

/// Tappable list tile with a "Soon" badge — every entry in Phase 0 is in this
/// state. Tap shows a snackbar pointing at the phase that ships the feature.
/// When the corresponding phase ships, swap the snackbar for `context.go(...)`
/// to the real page.
class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.comingSoonMessage,
  });

  final IconData icon;
  final String title;
  final String comingSoonMessage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          l.moreComingSoonBadge,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(comingSoonMessage)));
      },
    );
  }
}
