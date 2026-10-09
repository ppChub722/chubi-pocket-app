import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';

/// Floating pill bottom navigation:
///
/// `( [Dashboard] [Transactions] [ + ] [Accounts] [☰ More] )`
///
/// Four tab destinations (Dashboard=0 / Transactions=1 / Accounts=2 /
/// More=3) switch the [StatefulNavigationShell] branch on tap; the selected
/// one expands into an icon + label capsule while the rest stay icon-only.
/// The centre `+` is an oversized button centred on the bar (it pokes out
/// above and below, ringed in the page colour) and opens the
/// QuickAdd transaction modal. More is a real tab whose root is the card hub
/// (`/more`) — Projects / Categories / Tags / etc. stack inside it.
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
    required this.onMorePressed,
    this.moreSelected = false,
    super.key,
  });

  /// Branch index of the active destination tab
  /// (Dashboard=0, Transactions=1, Accounts=2). `+` and `More` are
  /// actions, not branches, so they never drive this value.
  final int currentIndex;

  /// True on a "More"-menu page (contacts, categories, …): the More slot
  /// lights up instead of the branch the page happens to be stacked on.
  final bool moreSelected;

  /// Called with the target branch index (0, 1, or 2).
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;
  final VoidCallback onMorePressed;

  /// Bar height, and the `+` button's outer size (ring included) — larger
  /// than the bar so it pokes out evenly above and below, centred on it.
  static const double _barHeight = 64;
  static const double _addSize = 76;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        // The whole `+` sits inside this box (bar centred in it), so the
        // part sticking out of the bar is still tappable.
        child: SizedBox(
          height: _addSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Material(
                color: scheme.surfaceContainerHigh,
                elevation: 8,
                shadowColor: scheme.shadow.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: SizedBox(
                  height: _barHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: AppIcons.dashboard,
                          iconSelected: AppIcons.dashboardActive,
                          label: l.navDashboard,
                          selected: !moreSelected && currentIndex == 0,
                          onTap: () => onTabSelected(0),
                        ),
                        _NavItem(
                          icon: AppIcons.transactions,
                          iconSelected: AppIcons.transactionsActive,
                          label: l.navTransactions,
                          selected: !moreSelected && currentIndex == 1,
                          onTap: () => onTabSelected(1),
                        ),
                        // Room for the `+` stacked on top.
                        const SizedBox(width: _addSize),
                        _NavItem(
                          icon: AppIcons.wallet,
                          iconSelected: AppIcons.walletActive,
                          label: l.navAccounts,
                          selected: !moreSelected && currentIndex == 2,
                          onTap: () => onTabSelected(2),
                        ),
                        _NavItem(
                          icon: AppIcons.more,
                          iconSelected: AppIcons.more,
                          label: l.navMore,
                          selected: moreSelected,
                          onTap: onMorePressed,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _AddButton(
                size: _addSize,
                tooltip: l.navAddTransaction,
                onPressed: onAddPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centre `+` — a big filled circle wrapped in a page-coloured ring, so it
/// reads as punched through the bar (a notch on both edges).
class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.size,
    required this.tooltip,
    required this.onPressed,
  });

  /// Outer diameter, ring included.
  final double size;
  final String tooltip;
  final VoidCallback onPressed;

  static const double _ring = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(_ring),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Material(
          color: scheme.primary,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: scheme.primary.withValues(alpha: 0.6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Icon(AppIcons.add, size: 32, color: scheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single tab — icon-only when idle; when [selected] a tinted capsule grows
/// around the icon and the label slides in beside it.
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
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? AppSpacing.md : AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? iconSelected : icon, size: 24, color: fg),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Text(
                            label,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
