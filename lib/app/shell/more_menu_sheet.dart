import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';

/// Bottom sheet shown when the user taps `More` on the bottom nav.
///
/// Lists features that don't have a primary tab, grouped by **function**
/// (not phase) and separated with thin dividers. Each entry is either a
/// shipped route or a "Soon" stub waiting for its module to land. As
/// features ship, swap `comingSoonMessage` → `route` on the matching
/// `_MoreItem`.
///
/// Groups (top → bottom):
///
/// 1. **Library** — taxonomy of the user's own data.
///    Categories, Tags.
/// 2. **People & Money flow** — collaboration / IOU tracking.
///    Contacts, Projects, Debts.
/// 3. **Planning** — forward-looking allocations & schedules.
///    Budgets, Saving goals, Scheduled.
///
/// Notifications: reachable from the bell in the top bar, intentionally
/// not duplicated here. Profile / Settings / Logout: behind the avatar
/// tap in the top bar (`/settings`).
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
            // Group 1 — Library (taxonomy of the user's own data).
            _MoreItem(
              icon: Icons.category_outlined,
              title: l.moreCategories,
              route: '/categories',
            ),
            _MoreItem(
              icon: Icons.sell_outlined,
              title: l.moreTags,
              route: '/tags',
            ),
            const Divider(height: 1),
            // Group 2 — People & money flow (collaboration / IOU).
            _MoreItem(
              icon: Icons.contacts_outlined,
              title: l.moreContacts,
              route: '/contacts',
            ),
            _MoreItem(
              icon: Icons.groups_outlined,
              title: l.moreProjects,
              route: '/projects',
            ),
            _MoreItem(
              icon: Icons.account_balance_outlined,
              title: l.moreDebts,
              route: '/personal-debts',
            ),
            const Divider(height: 1),
            // Group 3 — Planning (forward-looking).
            // (Notifications entry removed — inbox is reachable from the
            // bell in the top bar; no need to surface it twice.)
            _MoreItem(
              icon: Icons.savings_outlined,
              title: l.moreBudgets,
              route: '/budgets',
            ),
            _MoreItem(
              icon: Icons.flag_outlined,
              title: l.moreSavingGoals,
              route: '/saving-goals',
            ),
            _MoreItem(
              icon: Icons.schedule_outlined,
              title: l.moreScheduled,
              route: '/scheduled-transactions',
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable list tile with a "Soon" badge for unshipped features. Each
/// entry takes **either** a [route] (navigate via go_router and dismiss
/// the sheet) **or** a [comingSoonMessage] (show a snackbar). Exactly one
/// must be set.
///
/// As features ship, swap `comingSoonMessage` → `route` for that entry.
/// The "Soon" badge auto-disappears once a route is provided.
class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.title,
    this.route,
    this.comingSoonMessage,
  }) : assert(
          (route != null) ^ (comingSoonMessage != null),
          'Exactly one of `route` or `comingSoonMessage` must be set.',
        );

  final IconData icon;
  final String title;
  final String? route;
  final String? comingSoonMessage;

  bool get _isShipped => route != null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final titleColor =
        _isShipped ? scheme.onSurface : scheme.onSurfaceVariant;
    return ListTile(
      leading: Icon(
        icon,
        color: _isShipped ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: _isShipped
          ? Icon(Icons.chevron_right, color: scheme.onSurfaceVariant)
          : Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        if (_isShipped) {
          context.push(route!);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(comingSoonMessage!)));
        }
      },
    );
  }
}
