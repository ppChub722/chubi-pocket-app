import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// Phase 0 home — demonstrates the [EmptyView] state-pattern widget.
///
/// Phase 1 replaces this with the real home (account summary cards, recent
/// transactions, debt summary, FAB). The app-bar avatar entry to /settings is
/// the lasting piece of this scaffold.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appName),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final user = _userOf(state);
              if (user == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: l.homeSettingsTooltip,
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
      ),
      body: EmptyView(
        icon: Icons.savings_outlined,
        title: l.homeEmptyTitle,
        message: l.homeEmptyMessage,
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
