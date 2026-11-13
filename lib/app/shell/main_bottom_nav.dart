import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import 'nav_layout.dart';
import 'tab_nav.dart';

class MainBottomNav extends StatefulWidget {
  MainBottomNav({
    required this.current,
    required this.onSelected,
    required this.onAddPressed,
    List<ShellTab>? items,
    this.addWord,
    this.addColor,
    this.addIcon,
    super.key,
  }) : items = items ?? NavLayout.defaults.bottomItems;

  /// The + button's word, colour and icon as the open page gave them
  /// ([QuickCreateLook]); none = the plain บันทึก button.
  final String? addWord;
  final Color? addColor;
  final IconData? addIcon;

  /// The bar's items, left to right ([NavLayout.bottomItems]); the + sits
  /// after the first half.
  final List<ShellTab> items;

  /// The open tab; highlighted when it is one of [items].
  final ShellTab? current;

  final ValueChanged<ShellTab> onSelected;
  final VoidCallback onAddPressed;

  /// [tab]'s icon, selected icon and name in a bar.
  static (IconData, IconData, String) itemOf(
    AppLocalizations l,
    ShellTab tab,
  ) => switch (tab) {
    ShellTab.home => (
      AppIcons.dashboard,
      AppIcons.dashboardActive,
      l.navDashboard,
    ),
    ShellTab.transactions => (
      AppIcons.transactions,
      AppIcons.transactionsActive,
      l.navTransactions,
    ),
    ShellTab.accounts => (
      AppIcons.wallet,
      AppIcons.walletActive,
      l.navAccounts,
    ),
    ShellTab.more => (AppIcons.more, AppIcons.more, l.navMore),
    ShellTab.pending => (AppIcons.pending, AppIcons.pending, l.pendingTitle),
    ShellTab.notifications => (
      AppIcons.notifications,
      AppIcons.notifications,
      l.notificationsTitle,
    ),
    ShellTab.settings => (AppIcons.settings, AppIcons.settings, l.moreSettings),
    ShellTab.projects => (AppIcons.project, AppIcons.project, l.moreProjects),
    ShellTab.contacts => (AppIcons.contact, AppIcons.contact, l.moreContacts),
    ShellTab.budgets => (AppIcons.budget, AppIcons.budget, l.moreBudgets),
    ShellTab.recurring => (
      AppIcons.recurring,
      AppIcons.recurring,
      l.moreRecurring,
    ),
    ShellTab.savingGoals => (
      AppIcons.savingGoal,
      AppIcons.savingGoal,
      l.moreSavingGoals,
    ),
    ShellTab.debts => (AppIcons.debt, AppIcons.debt, l.moreDebts),
    ShellTab.categories => (
      AppIcons.category,
      AppIcons.category,
      l.moreCategories,
    ),
    ShellTab.tags => (AppIcons.tag, AppIcons.tag, l.moreTags),
  };

  /// The bar's height.
  static const double _barHeight = 64;

  static const double _radius = 24;

  static const double _tabInset = 6;

  static const double _barRadius = _radius + _tabInset;
  static const double _tabGap = 2;

  /// The round bump the bar grows round the centre button (owner 2026-11-12):
  /// wider than the bar, so it pokes out evenly above and below. The bar and
  /// the bump are ONE shape ([_NavShape]); the button (72) sits in it.
  static const double _addSize = 84;

  /// The centre slot's width for a tab row [rowWidth] wide: the bump's
  /// width and a little; the bar's items share the rest.
  static double addSlotFor(double rowWidth) =>
      (rowWidth * 0.26).clamp(88.0, 104.0);

  /// The button's word per mode.
  static String addLabel(AppLocalizations l, QuickCreateMode mode) =>
      switch (mode) {
        QuickCreateMode.tx => l.quickCreateBtnTx,
        QuickCreateMode.debt => l.quickCreateBtnDebt,
        QuickCreateMode.saving => l.quickCreateBtnSaving,
      };

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

  int get _count => widget.items.length;

  /// Slots before the + (the first half, rounded up).
  int get _split => (_count + 1) ~/ 2;

  int? get _selectedSlot {
    final current = widget.current;
    if (current == null) return null;
    final i = widget.items.indexOf(current);
    return i < 0 ? null : i;
  }

  @override
  void didUpdateWidget(MainBottomNav old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _landing = null;
  }

  double get _addSlot => MainBottomNav.addSlotFor(_rowWidth);

  double get _tabWidth => (_rowWidth - _addSlot) / _count;

  double _slotLeft(int s) => s * _tabWidth + (s >= _split ? _addSlot : 0);

  double _slotAt(double left) {
    for (var s = 0; s < _count - 1; s++) {
      final a = _slotLeft(s);
      final b = _slotLeft(s + 1);
      if (left <= b) return s + ((left - a) / (b - a)).clamp(0.0, 1.0);
    }
    return _count - 1.0;
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
    // No item of this bar is open (a top chip's page, a page only เพิ่มเติม
    // opens): the highlight followed the finger, now it just fades away.
    final moved = _selectedSlot != null && target != _selectedSlot;
    setState(() {
      _dragLeft = null;
      _landing = moved ? target : null;
    });
    if (!moved) return;
    HapticFeedback.selectionClick();
    widget.onSelected(widget.items[target]);
  }

  void _onDragCancel() {
    if (_dragLeft != null) setState(() => _dragLeft = null);
  }

  /// How far the highlight stretches past the first / last item.
  static const _maxStretch = 24.0;

  /// [left] kept on the items, with a damped stretch past either end (it
  /// eases back on release).
  double _clampLeft(double left) {
    final lo = _slotLeft(0);
    final hi = _slotLeft(_count - 1);
    if (left >= lo && left <= hi) return left;
    final over = left < lo ? left - lo : left - hi;
    final u = over / (_maxStretch * 3);
    return (over < 0 ? lo : hi) + _maxStretch * u / (1 + u.abs());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final still = MediaQuery.disableAnimationsOf(context);
    final dragLeft = _dragLeft;
    final lit = dragLeft != null
        ? _slotAt(dragLeft).round()
        : _landing ?? _selectedSlot;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PpForgeSpacing.lg,
          0,
          PpForgeSpacing.lg,
          PpForgeSpacing.sm,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          child: SizedBox(
            width: double.infinity,
            height: MainBottomNav._addSize,
            child: Stack(
              alignment: Alignment.center,
              // The bump and the button’s glow reach past the box.
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  // The same glass as the top bar's chips (MirrorSurface),
                  // cut to the bar + bump shape.
                  child: MirrorSurface(
                    shape: const _NavShapeBorder(),
                    bar: const GlassBar(
                      height: MainBottomNav._barHeight,
                      cornerRadius: MainBottomNav._barRadius,
                      bumpRadius: MainBottomNav._addSize / 2,
                    ),
                    // The app's one glass. Temporary fps probe:
                    // --dart-define=NO_NAV_BLUR=true drops the frost.
                    look: const bool.fromEnvironment('NO_NAV_BLUR')
                        ? PpForgeGlass.standard.withoutFrost()
                        : PpForgeGlass.standard,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Center(
                        child: SizedBox(
                          height: MainBottomNav._barHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  MainBottomNav._tabInset -
                                  MainBottomNav._tabGap,
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
                ),
                QuickCreateButton(
                  label:
                      widget.addWord ??
                      MainBottomNav.addLabel(l, QuickCreateMode.tx),
                  color: widget.addColor,
                  icon: widget.addIcon,
                  tooltip: widget.addWord ?? l.navAddTransaction,
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
        for (final (i, tab) in widget.items.indexed) ...[
          if (i == _split) SizedBox(width: _addSlot),
          _item(l, tab, lit == i, still),
        ],
      ],
    );
  }

  Widget _item(AppLocalizations l, ShellTab tab, bool selected, bool still) {
    final (icon, iconSelected, label) = MainBottomNav.itemOf(l, tab);
    return _NavItem(
      icon: icon,
      iconSelected: iconSelected,
      label: label,
      selected: selected,
      still: still,
      onTap: () => widget.onSelected(tab),
    );
  }
}

/// The bar's one shape: the capsule and the round bump at its middle,
/// united (owner 2026-11-12). The rect is the whole box — the bump's height —
/// and the bar is centred in it.
class _NavShapeBorder extends ShapeBorder {
  const _NavShapeBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const bar = MainBottomNav._barHeight;
    final top = rect.center.dy - bar / 2;
    return Path.combine(
      PathOperation.union,
      Path()..addRRect(
        RRect.fromLTRBR(
          rect.left,
          top,
          rect.right,
          top + bar,
          const Radius.circular(MainBottomNav._barRadius),
        ),
      ),
      Path()..addOval(
        Rect.fromCircle(
          center: rect.center,
          radius: MainBottomNav._addSize / 2,
        ),
      ),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;

  @override
  bool operator ==(Object other) => other is _NavShapeBorder;

  @override
  int get hashCode => 0;
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
    final grow = still ? Duration.zero : PpForgeDurations.chrome;
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
        curve: PpForgeDurations.chromeCurve,
        scale: visible ? 1 : 0,
        child: AnimatedOpacity(
          duration: grow,
          curve: PpForgeDurations.chromeCurve,
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
                  PpForgeIcon(
                    selected ? iconSelected : icon,
                    size: PpForgeIconSize.xl,
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
