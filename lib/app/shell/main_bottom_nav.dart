import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
    required this.onMorePressed,
    this.moreSelected = false,
    this.addMode = QuickCreateMode.tx,
    super.key,
  });

  final QuickCreateMode addMode;

  final int currentIndex;

  final bool moreSelected;

  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;
  final VoidCallback onMorePressed;

  /// Bar height, and the `+` button's outer size (ring included) — larger than
  /// the bar so it pokes out evenly above and below, centred on it.
  static const double _barHeight = 64;

  static const double _radius = 24;

  static const double _tabInset = 6;

  static const double _barRadius = _radius + _tabInset;
  static const double _tabGap = 2;
  static const double _addSize = 76;

  static const double _blur = 16;

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  static const _minFlingVelocity = 300.0;

  double _rowWidth = 0;

  /// The highlight's left edge while a finger drags it; null otherwise.
  double? _dragLeft;
  double _dragFrom = 0;
  double _dragDx = 0;

  int? _landing;

  int? _shownSlot;

  int _parkedSlot = 0;

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

  double _slotLeft(int s) =>
      s * _tabWidth + (s >= 2 ? MainBottomNav._addSize : 0);

  double _slotAt(double left) {
    for (var s = 0; s < 3; s++) {
      final a = _slotLeft(s);
      final b = _slotLeft(s + 1);
      if (left <= b) return s + ((left - a) / (b - a)).clamp(0.0, 1.0);
    }
    return 3;
  }

  void _onDragStart(DragStartDetails d) {
    final x =
        d.localPosition.dx - (MainBottomNav._tabInset - MainBottomNav._tabGap);
    final slot = _selectedSlot;
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
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          child: SizedBox(
            height: MainBottomNav._addSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                          padding: const EdgeInsets.symmetric(
                            horizontal:
                                MainBottomNav._tabInset - MainBottomNav._tabGap,
                          ),
                          child: LayoutBuilder(
                            builder: (context, box) {
                              _rowWidth = box.maxWidth;
                              final slot = _landing ?? _selectedSlot;
                              final shown = dragLeft != null || slot != null;
                              final appearing =
                                  shown &&
                                  _shownSlot == null &&
                                  dragLeft == null;
                              if (slot != null) _parkedSlot = slot;
                              _shownSlot = shown ? (slot ?? -1) : null;
                              return Stack(
                                children: [
                                  _SlidingHighlight(
                                    left: dragLeft ?? _slotLeft(_parkedSlot),
                                    width: _tabWidth,
                                    visible: shown,
                                    // Pinned to the finger; slides slot to slot
                                    // otherwise.
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
                QuickCreateButton(
                  mode: widget.addMode,
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

class _SlidingHighlight extends StatelessWidget {
  const _SlidingHighlight({
    required this.left,
    required this.width,
    required this.visible,
    required this.slide,
    required this.still,
  });

  final double left;

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
                  AppIcon(
                    selected ? iconSelected : icon,
                    size: AppIconSize.xl,
                    color: color,
                  ),
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
