import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_durations.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../features/pending/presentation/cubit/pending_cubit.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/buttons/app_icon_button.dart';
import '../../shared/icon_maker/icon_shape.dart';
import '../../shared/widgets/user_avatar.dart';
import 'fade_branch_container.dart';
import 'tab_nav.dart';
import 'top_bar_crumbs.dart';

/// Universal top bar — the top-chrome counterpart to `MainBottomNav`.
///
/// Same on every page, in every mode (owner rule 2026-10-09):
///
/// `[ ← │ Title ]                         [ ⏳ ] [ 🔔 ] [ 👤 ]`
///
/// - **Left**: optional back chip + a thin divider + the breadcrumb title.
/// - **Right**: the universal chips only — pending drafts, inbox, profile.
///
/// **No page actions, ever** — not add, not edit, not delete. They live in
/// the page body (pencil on the `HeaderCard`, `AddTile`s, a `DangerRow` at
/// the bottom in edit mode, …). There is deliberately no `actions`
/// parameter, so one can't creep back in.
///
/// The bar is transparent and pages float it over their content
/// (`Scaffold.extendBodyBehindAppBar: true`, first item padded by
/// `MediaQuery.paddingOf(context).top`).
///
/// Modes:
/// - **[editing]** (edit / reorder mode, forms): ← becomes ✕ (= cancel,
///   asks before discarding), the breadcrumb parent stops being a link and
///   the universal chips slide up out of view (owner 2026-10-09).
/// - **[showUniversal] false**: hides the chips — only where they can't
///   work (signed out) or on a whole-page form. Each chip opens its own
///   tab (รอยืนยัน, inbox, settings — [ShellTab]), as it was left; the
///   chip of the tab you're in returns to its root (owner 2026-10-09).
///
/// Motion (owner 2026-10-09 — the bar must not move between pages):
/// - Both halves are [Hero]es, so on push / back they stay put while the
///   page slides underneath. The left group cross-fades old → new (title,
///   breadcrumb, ← / ✕ / none).
/// - Hidden chips aren't removed: they're parked above the screen. Going
///   to such a page flies them up and out; coming back flies them down.
/// - Within one page (entering edit mode) the same changes animate in
///   place.
///
/// Implements [PreferredSizeWidget] so it drops straight into
/// `Scaffold.appBar`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    this.title,
    this.showBack = false,
    this.onBack,
    this.editing = false,
    this.showUniversal = true,
    this.parent,
    this.showParent = true,
    this.titleSlot,
    super.key,
  });

  final String? title;

  /// A page's own title widget, shown in place of [title] — anything (the
  /// transaction detail's "฿1,250 · อาหาร" once its amount scrolls away).
  /// Null = the plain [title]. Switching between the two, or to a slot
  /// with a different key, cross-fades like a title change; changes inside
  /// one slot don't (give it a new key to fade). It's styled as the title
  /// by default (titleMedium, one line, ellipsis).
  ///
  /// It rides the bar's left [Hero]: no Heroes or GlobalKeys inside (the
  /// flight builds a copy of it).
  final Widget? titleSlot;
  final bool showBack;

  /// Custom back handler; defaults to popping the current route.
  final VoidCallback? onBack;

  /// Edit-mode chrome: ✕ instead of ←.
  final bool editing;

  /// Whether to show the ⏳ / 🔔 / 👤 chips.
  final bool showUniversal;

  /// Breadcrumb parent (`โปรเจกต์ › test`). Null = derived from the route
  /// ([defaultTopBarCrumb]); pass one when the parent is a named item.
  final TopBarCrumb? parent;

  /// false = title only, even when a parent could be derived.
  final bool showParent;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  static const _leftTag = 'app-top-bar-left';
  static const _chipsTag = 'app-top-bar-chips';

  @override
  Widget build(BuildContext context) {
    final left = _LeftData(
      showBack: showBack || editing,
      backIcon: editing ? AppIcons.close : AppIcons.back,
      title: title,
      titleSlot: titleSlot,
      parent: showParent ? (parent ?? defaultTopBarCrumb(context)) : null,
      // Editing: leave only via ✕ (it asks before discarding).
      parentEnabled: !editing,
      onBack: onBack ?? () => _defaultBack(context),
    );
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      // The toolbar clips by default — chips sliding up would be cut at its
      // top edge instead of leaving the screen.
      clipBehavior: Clip.none,
      titleSpacing: AppSpacing.md,
      title: Align(
        alignment: Alignment.centerLeft,
        child: _LeftSlot(data: left),
      ),
      actions: [_ChipsSlot(hidden: editing || !showUniversal)],
    );
  }

  /// Left group in flight: the old one fades out while the new one fades
  /// in, each at its own size, pinned left — so a longer / shorter title or
  /// a ← appearing reads as a morph, not a jump. To / from a parked
  /// placeholder there's nothing to cross-fade: the real group just rides
  /// the flight ([_ParkingHero] fades it).
  static Widget _crossFadeShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final toward = _towardDestination(animation, direction);
    Widget sized(BuildContext heroContext) =>
        _pinned(heroContext, (heroContext.widget as Hero).child);

    if (_Parked.of(fromContext)) return sized(toContext);
    if (_Parked.of(toContext)) return sized(fromContext);
    return Stack(
      alignment: Alignment.topLeft,
      clipBehavior: Clip.none,
      children: [
        FadeTransition(
          opacity: ReverseAnimation(toward),
          child: sized(fromContext),
        ),
        FadeTransition(opacity: toward, child: sized(toContext)),
      ],
    );
  }

  /// [child] at its hero's own size, pinned to the shuttle's top-left.
  ///
  /// A flight places its shuttle by top *and* bottom offsets taken from the
  /// navigator's size when it starts. Opening an edit / create page hides
  /// the shell's bottom nav mid-flight, the navigator grows, and the
  /// shuttle box stretches with it — anything centred in it sank by half
  /// the nav's height, then snapped back up on landing (owner 2026-10-09:
  /// "เลื่อนลงแล้วเลื่อนขึ้น"). Pinned top-left it stays where the bar is.
  static Widget _pinned(BuildContext heroContext, Widget child) {
    final box = heroContext.findRenderObject() as RenderBox?;
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: 0,
      maxWidth: box?.size.width ?? double.infinity,
      minHeight: 0,
      maxHeight: box?.size.height ?? double.infinity,
      child: child,
    );
  }

  /// A flight's progress from its source to its destination, 0 → 1. (Pop
  /// drives it with the popped route's animation, which runs 1 → 0.)
  static Animation<double> _towardDestination(
    Animation<double> animation,
    HeroFlightDirection direction,
  ) => direction == HeroFlightDirection.push
      ? animation
      : ReverseAnimation(animation);

  /// Same as the system back gesture (owner 2026-10-10): `maybePop`, so a
  /// page's [PopScope] (discard prompt, edit mode, …) gets its say. On a
  /// tab's root (nothing to pop) it's the shell's back — the previous tab,
  /// the เพิ่มเติม hub, or the dashboard.
  Future<void> _defaultBack(BuildContext context) async {
    final shellBack = ShellBackScope.maybeOf(context);
    final handled = await Navigator.of(context).maybePop();
    if (!handled) shellBack?.call();
  }
}

/// The one way a top-bar part comes and goes (owner 2026-10-09: same
/// motion everywhere). A part that isn't shown is **parked** — lifted past
/// the top of the screen and faded out — never removed. Then:
/// - **push / back**: it's a [Hero], so it flies between where it sits on
///   each page — up and out, or down and in, when one page parks it;
/// - **in place** (edit mode on / off): it animates to / from parked;
/// - **tab switch**: `_LeftSlot` runs [park] off the shell's animation.
///
/// All three use [AppDurations.chrome] / [AppDurations.chromeCurve] and the
/// same lift + fade, so they look the same.
class _ParkingHero extends StatelessWidget {
  const _ParkingHero({
    required this.tag,
    required this.parked,
    required this.child,
    this.shuttle,
  });

  final Object tag;
  final bool parked;
  final Widget child;

  /// What flies; defaults to the destination's [child].
  final HeroFlightShuttleBuilder? shuttle;

  /// Lifts [child] by [p] of the way to parked (0 = in place, 1 = parked)
  /// and fades it to match.
  static Widget park(BuildContext context, double p, Widget child) {
    return Transform.translate(
      offset: Offset(0, -_lift(context) * p),
      child: Opacity(opacity: (1 - p).clamp(0.0, 1.0), child: child),
    );
  }

  /// Past the status bar and the bar itself.
  static double _lift(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).top + kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    final hero = _Parked(
      parked: parked,
      child: Hero(
        tag: tag,
        transitionOnUserGestures: true,
        flightShuttleBuilder: _shuttle,
        child: child,
      ),
    );
    return IgnorePointer(
      ignoring: parked,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: parked ? 1 : 0),
        duration: AppDurations.chrome,
        curve: AppDurations.chromeCurve,
        // The lift sits above the Hero, so a flight starts / ends at the
        // parked spot.
        builder: (context, p, hero) => park(context, p, hero!),
        child: hero,
      ),
    );
  }

  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final flying =
        shuttle?.call(
          flightContext,
          animation,
          direction,
          fromContext,
          toContext,
        ) ??
        AppTopBar._pinned(toContext, (toContext.widget as Hero).child);
    final from = _Parked.of(fromContext) ? 0.0 : 1.0;
    final to = _Parked.of(toContext) ? 0.0 : 1.0;
    return Material(
      // The navigator overlay has no Material for the parts' ink.
      type: MaterialType.transparency,
      child: from == to
          ? flying
          : FadeTransition(
              opacity: AppTopBar._towardDestination(animation, direction)
                  .drive(CurveTween(curve: AppDurations.chromeCurve))
                  .drive(Tween(begin: from, end: to)),
              child: flying,
            ),
    );
  }
}

/// Tells a flight whether its end is parked.
class _Parked extends InheritedWidget {
  const _Parked({required this.parked, required super.child});

  final bool parked;

  static bool of(BuildContext heroContext) =>
      heroContext.getInheritedWidgetOfExactType<_Parked>()?.parked ?? false;

  @override
  bool updateShouldNotify(_Parked old) => parked != old.parked;
}

/// What the left group shows — also what a branch reports to the shell so
/// the next tab can animate against it.
class _LeftData {
  const _LeftData({
    required this.showBack,
    required this.backIcon,
    required this.title,
    required this.parent,
    required this.parentEnabled,
    required this.onBack,
    this.titleSlot,
  });

  final bool showBack;
  final IconData backIcon;
  final String? title;
  final Widget? titleSlot;
  final TopBarCrumb? parent;
  final bool parentEnabled;
  final VoidCallback onBack;

  /// No ← and no title (the เพิ่มเติม hub) — nothing to show.
  bool get isEmpty => !showBack && title == null && titleSlot == null;

  _LeftGroup toWidget() => _LeftGroup(
    showBack: showBack,
    backIcon: backIcon,
    title: title,
    titleSlot: titleSlot,
    parent: parent,
    parentEnabled: parentEnabled,
    onBack: onBack,
  );
}

/// The left group as a [Hero], plus its motion when it appears / goes:
/// - **Empty** (เพิ่มเติม): parked above the screen, so a push / back to a
///   page that has one flies it down / up.
/// - **Tab switch** (no route change, so no hero): coming from a tab with
///   no group, this one drops in; going to one, the previous tab's group
///   rises out. Two tabs that both have one just swap.
class _LeftSlot extends StatelessWidget {
  const _LeftSlot({required this.data});

  final _LeftData data;

  @override
  Widget build(BuildContext context) {
    final Widget slot = _ParkingHero(
      tag: AppTopBar._leftTag,
      parked: data.isEmpty,
      shuttle: AppTopBar._crossFadeShuttle,
      child: data.isEmpty
          ? const SizedBox(width: 0, height: 40)
          : data.toWidget(),
    );

    final scope = TabSwitchScope.maybeOf(context);
    final branch = TabSwitchScope.branchOf(context);
    if (scope == null || branch == null) return slot;
    // Only the bar on top of its branch speaks for it.
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      scope.reportTopBar(branch, data);
    }
    final previous = scope.previous;
    if (branch != scope.current || previous == null) return slot;
    final before = scope.topBarOf(previous);
    final beforeEmpty = before is! _LeftData || before.isEmpty;
    if (beforeEmpty == data.isEmpty) return slot;

    return AnimatedBuilder(
      animation: scope.animation,
      builder: (context, _) {
        final t = scope.animation.value;
        if (t >= 1) return slot;
        // Drop in from parked.
        if (beforeEmpty) return _ParkingHero.park(context, 1 - t, slot);
        // Rise out: the previous tab's group, leaving.
        return Stack(
          clipBehavior: Clip.none,
          children: [
            slot,
            IgnorePointer(
              child: _ParkingHero.park(context, t, before.toWidget()),
            ),
          ],
        );
      },
    );
  }
}

/// The ⏳ / 🔔 / 👤 slot — parked (see [_ParkingHero]) when [hidden].
class _ChipsSlot extends StatelessWidget {
  const _ChipsSlot({required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context) => _ParkingHero(
    tag: AppTopBar._chipsTag,
    parked: hidden,
    child: const _UniversalChips(),
  );
}

/// The universal chips themselves.
class _UniversalChips extends StatelessWidget {
  const _UniversalChips();

  /// Opens a chip's tab, as it was left. Already in it → back to its root
  /// (inbox › settings → inbox), like re-tapping a nav tab.
  static void _open(BuildContext context, ShellTab tab, String path) {
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell == null) {
      // Outside the shell (tests, dev previews).
      GoRouter.maybeOf(context)?.push(path);
      return;
    }
    shell.goBranch(tab.index, initialLocation: shell.currentIndex == tab.index);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // In the top row's order, modules switched off left out (ShellRow /
    // AppModules) — the same order swipe walks between their pages.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tab in ShellRow.top.tabs) _chipFor(context, l, tab),
      ],
    );
  }

  Widget _chipFor(BuildContext context, AppLocalizations l, ShellTab tab) {
    return switch (tab) {
      // Pending drafts (รอยืนยัน).
      ShellTab.pending => BlocBuilder<PendingCubit, PendingState>(
        buildWhen: (a, b) => a.count != b.count,
        builder: (context, pending) => _chip(
          icon: AppIcons.pending,
          tooltip: l.pendingTooltip,
          badgeCount: pending.count,
          onPressed: () => _open(context, ShellTab.pending, '/pending'),
        ),
      ),
      // Notification inbox.
      ShellTab.notifications => BlocBuilder<UnreadBadgeCubit, int>(
        builder: (context, unread) => _chip(
          icon: AppIcons.notifications,
          tooltip: l.navNotificationsTooltip,
          badgeCount: unread,
          onPressed: () =>
              _open(context, ShellTab.notifications, '/notifications'),
        ),
      ),
      // Profile — the full avatar (no chip border), with a matching
      // shadow.
      ShellTab.settings => BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = _userOf(state);
          if (user == null) return const SizedBox(width: AppSpacing.sm);
          // The shadow + ripple follow the avatar's own shape (circle,
          // squircle, leaf, …) the user picked for their icon.
          final outline = IconShape.fromId(user.iconCode?.shape).radius(40);
          return Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.md,
            ),
            child: Tooltip(
              message: l.navProfileTooltip,
              child: InkWell(
                customBorder: RoundedRectangleBorder(borderRadius: outline),
                onTap: () => _open(context, ShellTab.settings, '/settings'),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: outline,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    displayName: user.displayName,
                    iconCode: user.iconCode,
                    size: 40,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      _ => throw ArgumentError('$tab has no top-bar chip'),
    };
  }

  /// A universal circular chip ([AppIconButton]) with left spacing.
  Widget _chip({
    required IconData icon,
    required String tooltip,
    required int badgeCount,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: AppIconButton(
        icon: icon,
        tooltip: tooltip,
        badgeCount: badgeCount,
        onPressed: onPressed,
      ),
    );
  }
}

/// The left group — one rounded background around the back button, a
/// divider and the breadcrumb title `หน้าแม่ › หน้านี้` (parent muted and
/// tappable, capped at ~40% of the screen; the page title ellipsizes first).
class _LeftGroup extends StatelessWidget {
  const _LeftGroup({
    required this.showBack,
    required this.title,
    required this.onBack,
    this.parent,
    this.parentEnabled = true,
    this.backIcon = AppIcons.back,
    this.titleSlot,
  });

  final bool showBack;
  final String? title;

  /// Replaces [title] — see [AppTopBar.titleSlot].
  final Widget? titleSlot;
  final VoidCallback onBack;
  final TopBarCrumb? parent;
  final bool parentEnabled;
  final IconData backIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final crumb = parent;
    final slot = titleSlot;
    final hasTitle = title != null || slot != null;
    if (!showBack && !hasTitle) return const SizedBox.shrink();
    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 1.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      // In-page changes (← ↔ ✕ ↔ none, new title) resize smoothly; the
      // clip makes a ← appearing read as sliding out of the chip.
      child: AnimatedSize(
        duration: AppDurations.chrome,
        curve: AppDurations.chromeCurve,
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBack) ...[
                InkWell(
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppDurations.chrome,
                      switchInCurve: AppDurations.chromeCurve,
                      switchOutCurve: AppDurations.chromeCurve,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: RotationTransition(
                          turns: Tween<double>(
                            begin: -0.125,
                            end: 0,
                          ).animate(a),
                          child: child,
                        ),
                      ),
                      child: Icon(backIcon, key: ValueKey(backIcon), size: 20),
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: scheme.outlineVariant),
              ],
              if (crumb != null) ...[
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                  ),
                  child: InkWell(
                    onTap: parentEnabled
                        ? () => goToCrumb(context, crumb)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        crumb.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                Icon(
                  AppIcons.chevronRight,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ],
              if (hasTitle)
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      crumb != null ? AppSpacing.xs : AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    // Title ↔ title, title ↔ slot: a cross-fade in place
                    // (none with animations off).
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : AppDurations.chrome,
                      switchInCurve: AppDurations.chromeCurve,
                      switchOutCurve: AppDurations.chromeCurve,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: slot != null
                          ? KeyedSubtree(
                              key:
                                  slot.key ??
                                  const ValueKey('app-top-bar-title-slot'),
                              child: DefaultTextStyle.merge(
                                style: textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                child: slot,
                              ),
                            )
                          : Text(
                              title!,
                              key: ValueKey(title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium,
                            ),
                    ),
                  ),
                )
              else
                const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

User? _userOf(AuthState state) {
  if (state is AuthAuthenticated) return state.user;
  if (state is AuthLoading && state.previous is AuthAuthenticated) {
    return (state.previous as AuthAuthenticated).user;
  }
  return null;
}
