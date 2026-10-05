import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/user_avatar.dart';

/// A local (page-specific) action for [AppTopBar], rendered as an icon chip
/// to the left of the universal notification + profile chips.
class AppBarAction {
  const AppBarAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final int badgeCount;
}

/// Universal top bar — the top-chrome counterpart to `MainBottomNav`.
///
/// Same on every page: a **transparent** bar (blends into the page; it still
/// occupies its row, content starts below it) where every icon sits in its
/// own circular chip. Layout:
///
/// `[ ← │ Title ]               [ …local ] [ 🔔 ] [ 👤 ]`
///
/// - **Left**: optional back chip + a thin divider + the title (left-aligned).
/// - **Right**: page-specific [actions], then the always-present
///   notification + profile chips.
///
/// Implements [PreferredSizeWidget] so it drops straight into
/// `Scaffold.appBar`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    this.title,
    this.showBack = false,
    this.onBack,
    this.actions = const <AppBarAction>[],
    super.key,
  });

  final String? title;
  final bool showBack;

  /// Custom back handler; defaults to popping the current route.
  final VoidCallback? onBack;

  /// Page-specific action chips, shown left of the universal chips.
  final List<AppBarAction> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.md,
      title: _LeftGroup(
        showBack: showBack,
        title: title,
        onBack: onBack ?? () => _defaultBack(context),
      ),
      actions: [
        for (final a in actions) _actionChip(context, a),
        // Separate the page-local actions from the universal ones. Only a
        // left margin here — the next chip brings its own left padding, so
        // the divider sits evenly between the two groups.
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Container(
              width: 2,
              height: 24,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        // Universal: notification inbox.
        BlocBuilder<UnreadBadgeCubit, int>(
          builder: (context, unread) => _actionChip(
            context,
            AppBarAction(
              icon: Icons.notifications_outlined,
              tooltip: l.navNotificationsTooltip,
              onPressed: () => context.push('/notifications'),
              badgeCount: unread,
            ),
          ),
        ),
        // Universal: profile — the full avatar (no chip border), with a
        // matching shadow.
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final user = _userOf(state);
            if (user == null) return const SizedBox(width: AppSpacing.sm);
            return Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.sm, right: AppSpacing.md),
              child: Tooltip(
                message: l.navProfileTooltip,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push('/settings'),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.2),
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
      ],
    );
  }

  void _defaultBack(BuildContext context) {
    if (context.canPop()) context.pop();
  }

  /// A circular action chip — matching the left group's bg + grey border +
  /// small shadow — with an optional badge.
  Widget _actionChip(BuildContext context, AppBarAction a) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icon(a.icon, size: 22);
    final visual = a.badgeCount > 0
        ? Badge(
            label: Text(a.badgeCount > 99 ? '99+' : '${a.badgeCount}'),
            child: icon,
          )
        : icon;
    Widget chip = Material(
      color: scheme.surfaceContainerHigh,
      elevation: 1.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: a.onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: visual),
        ),
      ),
    );
    if (a.tooltip != null) {
      chip = Tooltip(message: a.tooltip!, child: chip);
    }
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: chip,
    );
  }
}

/// The left group — a single rounded background wrapping the back button,
/// a divider, and the title (so the background covers the title too).
class _LeftGroup extends StatelessWidget {
  const _LeftGroup({
    required this.showBack,
    required this.title,
    required this.onBack,
  });

  final bool showBack;
  final String? title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!showBack && title == null) return const SizedBox.shrink();
    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 1.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBack) ...[
              InkWell(
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Icon(Icons.arrow_back, size: 20),
                ),
              ),
              Container(width: 1, height: 20, color: scheme.outlineVariant),
            ],
            if (title != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              )
            else
              const SizedBox(width: AppSpacing.xs),
          ],
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
