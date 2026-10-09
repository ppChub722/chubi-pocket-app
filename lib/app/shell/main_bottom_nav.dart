import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';

/// Floating rounded-rect bottom navigation:
///
/// `( [Dashboard] [Transactions] [ + ] [Accounts] [☰ More] )`
///
/// Four tab destinations (Dashboard=0 / Transactions=1 / Accounts=2 /
/// More=3) switch the [StatefulNavigationShell] branch on tap. Every tab is
/// an icon over a small label; the selected one's whole block is tinted
/// (owner 2026-10-09: the expanding capsule shifted the bar).
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

  /// The selected tab's highlight corner. Must stay ≤ its half-height
  /// (`_barHeight / 2 - _tabInset`) or it clamps to a pill.
  static const double _radius = 24;

  /// Gap between the bar's edge and a tab's highlight, on every side.
  static const double _tabInset = 6;

  /// The bar's corner = highlight + gap, so the two curves look the same
  /// (owner 2026-10-09: an equal radius made the outer one read tighter).
  static const double _barRadius = _radius + _tabInset;
  static const double _tabGap = 2;
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
                  borderRadius: BorderRadius.circular(_barRadius),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: SizedBox(
                  height: _barHeight,
                  child: Padding(
                    // + each tab's own [_tabGap] = [_tabInset] at the ends.
                    padding: const EdgeInsets.symmetric(
                      horizontal: _tabInset - _tabGap,
                    ),
                    child: LayoutBuilder(
                      builder: (context, box) => Stack(
                        children: [
                          _SlidingHighlight(
                            slot: _selectedSlot,
                            width: box.maxWidth,
                          ),
                          _tabs(l),
                        ],
                      ),
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

  /// 0 dashboard · 1 transactions · 2 wallets · 3 more; null = none.
  int? get _selectedSlot => moreSelected
      ? 3
      : currentIndex >= 0 && currentIndex <= 2
      ? currentIndex
      : null;

  Widget _tabs(AppLocalizations l) {
    return Row(
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
    );
  }
}

/// The selected tab's tint — one block that slides between tab slots
/// (crossing under the `+`) instead of each tab fading its own.
class _SlidingHighlight extends StatelessWidget {
  const _SlidingHighlight({required this.slot, required this.width});

  final int? slot;

  /// The tab row's width (bar minus its side padding).
  final double width;

  @override
  Widget build(BuildContext context) {
    const gap = MainBottomNav._tabGap;
    final tabWidth = (width - MainBottomNav._addSize) / 4;
    // Slots 2 and 3 sit past the `+` gap.
    double slotLeft(int s) =>
        s * tabWidth + (s >= 2 ? MainBottomNav._addSize : 0);
    final s = slot ?? 0;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: slotLeft(s) + gap,
      width: tabWidth - gap * 2,
      top: MainBottomNav._tabInset,
      bottom: MainBottomNav._tabInset,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: slot == null ? 0 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(MainBottomNav._radius),
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

/// Single tab — icon over a small label, always both. The tint behind the
/// selected one is [_SlidingHighlight]; here [selected] only recolours
/// (animated) and bolds the label. Nothing changes width, so the bar never
/// shifts when switching tabs.
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

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MainBottomNav._tabGap,
            vertical: MainBottomNav._tabInset,
          ),
          // No ink ripple (owner 2026-10-09) — the sliding highlight is the
          // tap feedback.
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: fg),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, color, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? iconSelected : icon, size: 28, color: color),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      height: 1.2,
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
