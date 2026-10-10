import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_durations.dart';
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
///
/// **Swipe along the bar = switch tab** (owner 2026-10-10), on every tab —
/// a content swipe may belong to the page (the dashboard's month). The
/// highlight follows the finger; on release it lands on the nearest slot,
/// or the next one in a fling's direction, with a haptic. Taps still work:
/// the drag only wins once the finger travels, so a drag that starts on the
/// `+` scrubs too while a tap on it opens quick create.
class MainBottomNav extends StatefulWidget {
  const MainBottomNav({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
    required this.onMorePressed,
    this.moreSelected = false,
    super.key,
  });

  /// Branch index of the active tab (Dashboard=0, Transactions=1,
  /// Accounts=2). Any other tab (a เพิ่มเติม card, ⏳ 🔔 👤) lights no slot.
  final int currentIndex;

  /// True only on the เพิ่มเติม hub itself — its cards' tabs don't light
  /// it (owner 2026-10-09).
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

  /// Frosted-glass blur behind the bar.
  static const double _blur = 16;

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  /// A release this fast (px/s) moves on to the next slot that way.
  static const _minFlingVelocity = 300.0;

  /// The tab row's width (bar minus its side padding), from layout.
  double _rowWidth = 0;

  /// The highlight's left edge while a finger drags it; null otherwise.
  double? _dragLeft;
  double _dragFrom = 0;
  double _dragDx = 0;

  /// Where a released drag landed, shown until the parent catches up.
  int? _landing;

  /// The slot the highlight showed at last build (−1: riding a drag with
  /// no slot lit), null while hidden — tells a slot-to-slot slide from a
  /// grow-in after a slotless tab.
  int? _shownSlot;

  /// The slot the highlight last sat in — where it shrinks away / waits.
  int _parkedSlot = 0;

  /// 0 dashboard · 1 transactions · 2 wallets · 3 more; null = none.
  int? get _selectedSlot => widget.moreSelected
      ? 3
      : widget.currentIndex >= 0 && widget.currentIndex <= 2
      ? widget.currentIndex
      : null;

  @override
  void didUpdateWidget(MainBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex ||
        old.moreSelected != widget.moreSelected) {
      _landing = null;
    }
  }

  double get _tabWidth => (_rowWidth - MainBottomNav._addSize) / 4;

  /// Left edge of slot [s] in the row (slots 2 and 3 sit past the `+`).
  double _slotLeft(int s) =>
      s * _tabWidth + (s >= 2 ? MainBottomNav._addSize : 0);

  /// Where a highlight at [left] sits, in slots (fractional between two).
  double _slotAt(double left) {
    for (var s = 0; s < 3; s++) {
      final a = _slotLeft(s);
      final b = _slotLeft(s + 1);
      if (left <= b) return s + ((left - a) / (b - a)).clamp(0.0, 1.0);
    }
    return 3;
  }

  void _onDragStart(DragStartDetails d) {
    // Row coordinates: the bar pads the row by (inset − gap) each side.
    final x =
        d.localPosition.dx - (MainBottomNav._tabInset - MainBottomNav._tabGap);
    final slot = _selectedSlot;
    // From the lit slot; with none lit (another tab), from under the finger.
    _dragFrom = slot != null ? _slotLeft(slot) : x - _tabWidth / 2;
    _dragDx = 0;
    setState(() => _dragLeft = _clampLeft(_dragFrom));
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_dragLeft == null) return;
    _dragDx += d.delta.dx;
    setState(() => _dragLeft = _clampLeft(_dragFrom + _dragDx));
  }

  void _onDragEnd(DragEndDetails d) {
    final left = _dragLeft;
    if (left == null) return;
    final at = _slotAt(left);
    final v = d.primaryVelocity ?? 0;
    final target = v > _minFlingVelocity
        ? at.ceil()
        : v < -_minFlingVelocity
        ? at.floor()
        : at.round();
    final moved = target != _selectedSlot;
    setState(() {
      _dragLeft = null;
      _landing = moved ? target : null;
    });
    if (!moved) return;
    HapticFeedback.selectionClick();
    target == 3 ? widget.onMorePressed() : widget.onTabSelected(target);
  }

  void _onDragCancel() {
    if (_dragLeft != null) setState(() => _dragLeft = null);
  }

  double _clampLeft(double left) => left.clamp(_slotLeft(0), _slotLeft(3));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    final dragLeft = _dragLeft;
    // Mid-drag the slot under the highlight lights up; then the landing
    // slot until the tab switch arrives.
    final lit = dragLeft != null
        ? _slotAt(dragLeft).round()
        : _landing ?? _selectedSlot;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          // Count from touch-down so the highlight stays under the finger
          // (no slop lag).
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          // The whole `+` sits inside this box (bar centred in it), so the
          // part sticking out of the bar is still tappable.
          child: SizedBox(
            height: MainBottomNav._addSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Frosted glass (owner 2026-10-10: see-through): the page
                // scrolls on underneath, blurred. No elevation — a shadow
                // would show through the tint as a dark smudge.
                ClipRRect(
                  borderRadius: BorderRadius.circular(MainBottomNav._barRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: MainBottomNav._blur,
                      sigmaY: MainBottomNav._blur,
                    ),
                    child: Material(
                      color: scheme.surfaceContainerHigh.withValues(
                        alpha: 0.72,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          MainBottomNav._barRadius,
                        ),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: SizedBox(
                        height: MainBottomNav._barHeight,
                        child: Padding(
                          // + each tab's own [_tabGap] = [_tabInset] at the
                          // ends.
                          padding: const EdgeInsets.symmetric(
                            horizontal:
                                MainBottomNav._tabInset - MainBottomNav._tabGap,
                          ),
                          child: LayoutBuilder(
                            builder: (context, box) {
                              _rowWidth = box.maxWidth;
                              final slot = _landing ?? _selectedSlot;
                              final shown = dragLeft != null || slot != null;
                              // Back from a slotless tab: grow in at the
                              // new slot — nothing was shown in between,
                              // so no slide across from the old one.
                              final appearing =
                                  shown &&
                                  _shownSlot == null &&
                                  dragLeft == null;
                              if (slot != null) _parkedSlot = slot;
                              _shownSlot = shown ? (slot ?? -1) : null;
                              return Stack(
                                children: [
                                  _SlidingHighlight(
                                    // Hidden: shrinks away where it was.
                                    left: dragLeft ?? _slotLeft(_parkedSlot),
                                    width: _tabWidth,
                                    visible: shown,
                                    // Pinned to the finger; slides slot to
                                    // slot otherwise.
                                    slide: dragLeft == null && !appearing,
                                    still: still,
                                  ),
                                  _tabs(l, lit, still),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _AddButton(
                  size: MainBottomNav._addSize,
                  tooltip: l.navAddTransaction,
                  onPressed: widget.onAddPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs(AppLocalizations l, int? lit, bool still) {
    return Row(
      children: [
        _NavItem(
          icon: AppIcons.dashboard,
          iconSelected: AppIcons.dashboardActive,
          label: l.navDashboard,
          selected: lit == 0,
          still: still,
          onTap: () => widget.onTabSelected(0),
        ),
        _NavItem(
          icon: AppIcons.transactions,
          iconSelected: AppIcons.transactionsActive,
          label: l.navTransactions,
          selected: lit == 1,
          still: still,
          onTap: () => widget.onTabSelected(1),
        ),
        // Room for the `+` stacked on top.
        const SizedBox(width: MainBottomNav._addSize),
        _NavItem(
          icon: AppIcons.wallet,
          iconSelected: AppIcons.walletActive,
          label: l.navAccounts,
          selected: lit == 2,
          still: still,
          onTap: () => widget.onTabSelected(2),
        ),
        _NavItem(
          icon: AppIcons.more,
          iconSelected: AppIcons.more,
          label: l.navMore,
          selected: lit == 3,
          still: still,
          onTap: widget.onMorePressed,
        ),
      ],
    );
  }
}

/// The selected tab's tint — one block that slides between tab slots
/// (crossing under the `+`) instead of each tab fading its own, and rides
/// the finger during a bar swipe. On a tab with no slot it shrinks away
/// into its slot's centre (and grows back out of the slot it returns to;
/// owner 2026-10-10). Instant under reduced motion ([still]).
class _SlidingHighlight extends StatelessWidget {
  const _SlidingHighlight({
    required this.left,
    required this.width,
    required this.visible,
    required this.slide,
    required this.still,
  });

  /// The slot's left edge in the tab row (gap not yet applied).
  final double left;

  /// One tab slot's width.
  final double width;
  final bool visible;

  /// Animate a change of [left] (slot to slot); otherwise jump to it.
  final bool slide;
  final bool still;

  @override
  Widget build(BuildContext context) {
    const gap = MainBottomNav._tabGap;
    final grow = still ? Duration.zero : AppDurations.chrome;
    return AnimatedPositioned(
      duration: slide && !still
          ? const Duration(milliseconds: 300)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      left: left + gap,
      width: width - gap * 2,
      top: MainBottomNav._tabInset,
      bottom: MainBottomNav._tabInset,
      child: AnimatedScale(
        duration: grow,
        curve: AppDurations.chromeCurve,
        scale: visible ? 1 : 0,
        child: AnimatedOpacity(
          duration: grow,
          curve: AppDurations.chromeCurve,
          opacity: visible ? 1 : 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(MainBottomNav._radius),
            ),
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
/// (animated, instant when [still]) and bolds the label. Nothing changes
/// width, so the bar never shifts when switching tabs.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.selected,
    required this.still,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconSelected;
  final String label;
  final bool selected;

  /// Reduced motion — recolour without a tween.
  final bool still;
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
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
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
