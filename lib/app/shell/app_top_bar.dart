import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../features/pending/presentation/cubit/pending_cubit.dart';
import '../../l10n/gen/app_localizations.dart';
import 'fade_branch_container.dart';
import 'tab_nav.dart';
import 'top_bar_crumbs.dart';
import '../../ui/ui.dart';

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

  final Widget? titleSlot;
  final bool showBack;

  final VoidCallback? onBack;

  /// Edit-mode chrome: ✕ instead of ←.
  final bool editing;

  final bool showUniversal;

  final TopBarCrumb? parent;

  final bool showParent;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  static const scrimKey = ValueKey('app-top-bar-scrim');

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
      parentEnabled: !editing,
      onBack: onBack ?? () => _defaultBack(context),
    );
    final inset = MediaQuery.paddingOf(context).top;
    return AppBar(
      flexibleSpace: TopScrim(key: scrimKey, inset: inset),
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      // The toolbar clips by default — chips sliding up would be cut at its top
      // edge instead of leaving the screen.
      clipBehavior: Clip.none,
      titleSpacing: AppSpacing.md,
      title: Align(
        alignment: Alignment.centerLeft,
        child: _LeftSlot(data: left),
      ),
      actions: [_ChipsSlot(hidden: editing || !showUniversal)],
    );
  }

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

  static Animation<double> _towardDestination(
    Animation<double> animation,
    HeroFlightDirection direction,
  ) => direction == HeroFlightDirection.push
      ? animation
      : ReverseAnimation(animation);

  Future<void> _defaultBack(BuildContext context) async {
    final shellBack = ShellBackScope.maybeOf(context);
    final handled = await Navigator.of(context).maybePop();
    if (!handled) shellBack?.call();
  }
}

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

  final HeroFlightShuttleBuilder? shuttle;

  static Widget park(BuildContext context, double p, Widget child) {
    return Transform.translate(
      offset: Offset(0, -_lift(context) * p),
      child: Opacity(opacity: (1 - p).clamp(0.0, 1.0), child: child),
    );
  }

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

class _Parked extends InheritedWidget {
  const _Parked({required this.parked, required super.child});

  final bool parked;

  static bool of(BuildContext heroContext) =>
      heroContext.getInheritedWidgetOfExactType<_Parked>()?.parked ?? false;

  @override
  bool updateShouldNotify(_Parked old) => parked != old.parked;
}

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
        if (beforeEmpty) return _ParkingHero.park(context, 1 - t, slot);
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

class _UniversalChips extends StatelessWidget {
  const _UniversalChips();

  static void _open(BuildContext context, ShellTab tab, String path) {
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell == null) {
      GoRouter.maybeOf(context)?.push(path);
      return;
    }
    shell.goBranch(tab.index, initialLocation: shell.currentIndex == tab.index);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    TickerMode.valuesOf(context);
    final shell = StatefulNavigationShell.maybeOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tab in ShellRow.top.tabs)
          _chipFor(context, l, tab, shell?.currentIndex == tab.index),
      ],
    );
  }

  Widget _chipFor(
    BuildContext context,
    AppLocalizations l,
    ShellTab tab,
    bool active,
  ) {
    return switch (tab) {
      ShellTab.pending => BlocBuilder<PendingCubit, PendingState>(
        buildWhen: (a, b) => a.count != b.count,
        builder: (context, pending) => _chip(
          icon: AppIcons.pending,
          tooltip: l.pendingTooltip,
          active: active,
          badgeCount: pending.count,
          onPressed: () => _open(context, ShellTab.pending, '/pending'),
        ),
      ),
      ShellTab.notifications => BlocBuilder<UnreadBadgeCubit, int>(
        builder: (context, unread) => _chip(
          icon: AppIcons.notifications,
          tooltip: l.navNotificationsTooltip,
          active: active,
          badgeCount: unread,
          onPressed: () =>
              _open(context, ShellTab.notifications, '/notifications'),
        ),
      ),
      ShellTab.settings => BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = _userOf(state);
          if (user == null) return const SizedBox(width: AppSpacing.sm);
          final outline = IconShape.fromId(user.iconCode?.shape).radius(40);
          return Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.md,
            ),
            child: AppAvatarButton(
              tooltip: l.navProfileTooltip,
              outline: outline,
              active: active,
              onTap: () => _open(context, ShellTab.settings, '/settings'),
              child: UserAvatar(
                displayName: user.displayName,
                iconCode: user.iconCode == null
                    ? null
                    : IconCode(
                        icon: user.iconCode!.icon,
                        iconColors: user.iconCode!.iconColors,
                        background: user.iconCode!.background,
                        bgColors: user.iconCode!.bgColors,
                        shape: user.iconCode!.shape,
                      ),
                size: 32,
              ),
            ),
          );
        },
      ),
      _ => throw ArgumentError('$tab has no top-bar chip'),
    };
  }

  Widget _chip({
    required IconData icon,
    required String tooltip,
    required int badgeCount,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: AppIconButton(
        icon: icon,
        tooltip: tooltip,
        badgeCount: badgeCount,
        selected: active,
        onPressed: onPressed,
      ),
    );
  }
}

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
                      child: AppIcon(
                        backIcon,
                        key: ValueKey(backIcon),
                        size: AppIconSize.md,
                      ),
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
                AppIcon(
                  AppIcons.chevronRight,
                  size: AppIconSize.sm,
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
