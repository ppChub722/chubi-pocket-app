import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../features/pending/presentation/cubit/pending_cubit.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/buttons/app_icon_button.dart';
import '../../shared/widgets/chips/filter_chips.dart';
import '../../shared/widgets/user_avatar.dart';
import 'top_bar_crumbs.dart';

/// A local (page-specific) action for [AppTopBar], rendered as an icon chip
/// to the left of the universal notification + profile chips.
class AppBarAction {
  const AppBarAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount = 0,
    this.destructive = false,
    this.enabled = true,
    this.label,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final int badgeCount;

  /// Red, labelled pill ("🗑 ลบ") — destructive actions always show text
  /// because they matter. Callers still confirm via `showConfirmDialog`.
  final bool destructive;

  /// false → dimmed and untappable (e.g. bulk actions with nothing selected).
  final bool enabled;

  /// Text for a [destructive] pill; defaults to the localized "ลบ".
  final String? label;
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
/// Modes:
/// - **[editing]** (edit / reorder mode, forms): back chip becomes ✕
///   (= cancel) and the universal chips are hidden — only the page's own
///   edit actions remain.
/// - **[showUniversal] false** (overlay layer: settings, notifications):
///   hides 🔔 👤 since the layer was opened from them.
///
/// Implements [PreferredSizeWidget] so it drops straight into
/// `Scaffold.appBar`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    this.title,
    this.showBack = false,
    this.onBack,
    this.actions = const <AppBarAction>[],
    this.editing = false,
    this.showUniversal = true,
    this.parent,
    this.showParent = true,
    super.key,
  });

  final String? title;
  final bool showBack;

  /// Custom back handler; defaults to popping the current route.
  final VoidCallback? onBack;

  /// Page-specific action chips, shown left of the universal chips.
  final List<AppBarAction> actions;

  /// Edit-mode chrome: ✕ instead of ←, no universal chips.
  final bool editing;

  /// Whether to show the 🔔 / 👤 chips (ignored while [editing]).
  final bool showUniversal;

  /// Breadcrumb parent (`โปรเจกต์ › test`). Null = derived from the route
  /// ([defaultTopBarCrumb]); pass one when the parent is a named item.
  final TopBarCrumb? parent;

  /// false = title only, even when a parent could be derived.
  final bool showParent;

  bool get _universal => showUniversal && !editing;

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
        showBack: showBack || editing,
        backIcon: editing ? AppIcons.close : AppIcons.back,
        title: title,
        parent: showParent ? (parent ?? defaultTopBarCrumb(context)) : null,
        // Editing: leave only via ✕ (it asks before discarding).
        parentEnabled: !editing,
        onBack: onBack ?? () => _defaultBack(context),
      ),
      actions: [
        for (final a in actions) _actionChip(context, a),
        if (!_universal)
          const SizedBox(width: AppSpacing.md)
        // Separate the page-local actions from the universal ones. Only a
        // left margin here — the next chip brings its own left padding, so
        // the divider sits evenly between the two groups.
        else if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Container(
              width: 2,
              height: 24,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        // Universal: pending drafts (รอยืนยัน), next to the inbox.
        if (_universal)
        BlocBuilder<PendingCubit, PendingState>(
          buildWhen: (a, b) => a.count != b.count,
          builder: (context, pending) => _actionChip(
            context,
            AppBarAction(
              icon: AppIcons.pending,
              tooltip: l.pendingTooltip,
              onPressed: () => context.push('/pending'),
              badgeCount: pending.count,
            ),
          ),
        ),
        // Universal: notification inbox.
        if (_universal)
        BlocBuilder<UnreadBadgeCubit, int>(
          builder: (context, unread) => _actionChip(
            context,
            AppBarAction(
              icon: AppIcons.notifications,
              tooltip: l.navNotificationsTooltip,
              onPressed: () => context.push('/notifications'),
              badgeCount: unread,
            ),
          ),
        ),
        // Universal: profile — the full avatar (no chip border), with a
        // matching shadow.
        if (_universal)
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

  /// A circular action chip ([AppIconButton]) with left spacing; destructive
  /// actions render as a red labelled [ActionPill] instead.
  Widget _actionChip(BuildContext context, AppBarAction a) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: a.destructive
          ? Tooltip(
              message: a.tooltip ?? '',
              child: ActionPill(
                icon: a.icon,
                label: a.label ?? AppLocalizations.of(context)!.commonDelete,
                destructive: true,
                onTap: a.enabled ? a.onPressed : null,
              ),
            )
          : AppIconButton(
              icon: a.icon,
              tooltip: a.tooltip,
              badgeCount: a.badgeCount,
              onPressed: a.enabled ? a.onPressed : null,
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
  });

  final bool showBack;
  final String? title;
  final VoidCallback onBack;
  final TopBarCrumb? parent;
  final bool parentEnabled;
  final IconData backIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final crumb = parent;
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Icon(backIcon, size: 20),
                ),
              ),
              Container(width: 1, height: 20, color: scheme.outlineVariant),
            ],
            if (crumb != null) ...[
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                child: InkWell(
                  onTap: parentEnabled ? () => goToCrumb(context, crumb) : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
                    child: Text(
                      crumb.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              Icon(AppIcons.chevronRight, size: 16, color: scheme.onSurfaceVariant),
            ],
            if (title != null)
              Flexible(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    crumb != null ? AppSpacing.xs : AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
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
