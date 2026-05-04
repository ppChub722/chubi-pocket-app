import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';

/// Five-slot bottom navigation:
///
/// `[Dashboard] [Transactions] [+ Add (FAB)] [Accounts] [☰ More]`
///
/// Three of the five are tab destinations (Dashboard=0 / Transactions=1 /
/// Accounts=2) and switch the [StatefulNavigationShell] branch on tap.
/// The center `+` opens the QuickAdd transaction modal. `☰ More` opens
/// the [MoreMenuSheet] without changing the active branch — Projects /
/// Categories / Tags / etc. live there.
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
    required this.onMorePressed,
    super.key,
  });

  /// Branch index of the active destination tab
  /// (Dashboard=0, Transactions=1, Accounts=2). `+` and `More` are
  /// actions, not branches, so they never drive this value.
  final int currentIndex;

  /// Called with the target branch index (0, 1, or 2).
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      padding: EdgeInsets.zero,
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.dashboard_outlined,
            iconSelected: Icons.dashboard,
            label: l.navDashboard,
            selected: currentIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          _NavItem(
            icon: Icons.list_alt_outlined,
            iconSelected: Icons.list_alt,
            label: l.navTransactions,
            selected: currentIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          // Spacer for the docked FAB (the actual `+` button is rendered by
          // the [Scaffold.floatingActionButton] above this bar).
          const SizedBox(width: 56),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            iconSelected: Icons.account_balance_wallet,
            label: l.navAccounts,
            selected: currentIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          _NavItem(
            icon: Icons.more_horiz,
            iconSelected: Icons.more_horiz,
            label: l.navMore,
            selected: false,
            onTap: onMorePressed,
          ),
        ],
      ),
    );
  }
}

/// Single tab button — icon-over-label, with an M3-style filled pill behind
/// the icon when [selected].
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconSelected;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor =
        selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final labelColor =
        selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? scheme.secondaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selected ? iconSelected : icon,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
