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
import '../../shared/icon_maker/icon_shape.dart';
import '../../shared/widgets/user_avatar.dart';
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
///   asks before discarding) and the breadcrumb parent stops being a link.
///   The universal chips stay — opening them pushes an overlay page, so the
///   edit in progress is still there on return.
/// - **[showUniversal] false** (overlay layer: settings, notifications):
///   hides the chips since the layer was opened from them.
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
    super.key,
  });

  final String? title;
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
        if (!showUniversal) const SizedBox(width: AppSpacing.md),
        // Pending drafts (รอยืนยัน), next to the inbox.
        if (showUniversal)
          BlocBuilder<PendingCubit, PendingState>(
            buildWhen: (a, b) => a.count != b.count,
            builder: (context, pending) => _chip(
              icon: AppIcons.pending,
              tooltip: l.pendingTooltip,
              badgeCount: pending.count,
              onPressed: () => context.push('/pending'),
            ),
          ),
        // Notification inbox.
        if (showUniversal)
          BlocBuilder<UnreadBadgeCubit, int>(
            builder: (context, unread) => _chip(
              icon: AppIcons.notifications,
              tooltip: l.navNotificationsTooltip,
              badgeCount: unread,
              onPressed: () => context.push('/notifications'),
            ),
          ),
        // Profile — the full avatar (no chip border), with a matching
        // shadow.
        if (showUniversal)
          BlocBuilder<AuthCubit, AuthState>(
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
                    onTap: () => context.push('/settings'),
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
      ],
    );
  }

  void _defaultBack(BuildContext context) {
    if (context.canPop()) context.pop();
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
                  maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                ),
                child: InkWell(
                  onTap: parentEnabled ? () => goToCrumb(context, crumb) : null,
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
