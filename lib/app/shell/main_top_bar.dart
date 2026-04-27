import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/user_avatar.dart';

/// Global top app bar shown above every shell tab.
///
/// Right-side actions are stable across tabs:
/// - 🔔 Notifications — opens the in-app inbox in Phase 1b. Phase 0 shows a
///   "Coming soon" snackbar.
/// - 👤 Avatar — opens `/settings`, the user hub (profile, security,
///   appearance, language, font, logout).
///
/// Sub-pages (e.g. `/settings`, `/accounts/:id`) supply their own AppBar with
/// a back button — they are NOT inside the shell.
class MainTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MainTopBar({required this.title, super.key});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          tooltip: l.navNotificationsTooltip,
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotificationsComingSoon(context, l),
        ),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final user = _userOf(state);
            if (user == null) return const SizedBox(width: 8);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: l.navProfileTooltip,
                onPressed: () => context.push('/settings'),
                icon: UserAvatar(
                  displayName: user.displayName,
                  avatarUrl: user.avatarUrl,
                  size: 32,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNotificationsComingSoon(
    BuildContext context,
    AppLocalizations l,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l.notificationsComingSoon)),
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
