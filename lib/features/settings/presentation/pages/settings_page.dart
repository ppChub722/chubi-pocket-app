import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/fonts/font_registry.dart';
import '../../../../core/theme/theme_registry.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../preferences/presentation/cubit/font_id_cubit.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_id_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = _userOf(state);
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _ProfileCard(user: user),
              _SectionHeader(l.settingsSectionAccount),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l.settingsChangePassword),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/password'),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(l.settingsDefaultCurrency),
                subtitle: Text(user.currency),
              ),
              _SectionHeader(l.settingsSectionPreferences),
              const _ThemePicker(),
              const Divider(height: 0),
              const _ThemeModePicker(),
              const Divider(height: 0),
              const _LanguagePicker(),
              const Divider(height: 0),
              const _FontPicker(),
              _SectionHeader(l.settingsSectionAbout),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.settingsAppVersion),
                subtitle: Text(l.settingsAppVersionValue),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: Text(l.settingsLogout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.error),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsLogoutDialogTitle),
        content: Text(l.settingsLogoutDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.settingsLogout),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthCubit>().logout();
    }
  }
}

User? _userOf(AuthState state) {
  if (state is AuthAuthenticated) return state.user;
  if (state is AuthLoading && state.previous is AuthAuthenticated) {
    return (state.previous as AuthAuthenticated).user;
  }
  return null;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/settings/profile'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                UserAvatar(
                  displayName: user.displayName,
                  iconCode: user.iconCode,
                  size: 56,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                      ),
                      if (user.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selectedId = context.watch<ThemeIdCubit>().state;
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l.settingsTheme),
      subtitle: Wrap(
        spacing: AppSpacing.sm,
        children: ThemeRegistry.all.map((t) {
          return ChoiceChip(
            label: Text(t.id),
            selected: t.id == selectedId,
            onSelected: (_) => context.read<ThemeIdCubit>().set(t.id),
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = context.watch<ThemeModeCubit>().state;
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: Text(l.settingsAppearance),
      subtitle: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(
              value: ThemeMode.light,
              label: Text(l.modeLight),
              icon: const Icon(Icons.light_mode_outlined)),
          ButtonSegment(
              value: ThemeMode.dark,
              label: Text(l.modeDark),
              icon: const Icon(Icons.dark_mode_outlined)),
          ButtonSegment(
              value: ThemeMode.system,
              label: Text(l.modeSystem),
              icon: const Icon(Icons.brightness_auto_outlined)),
        ],
        selected: {mode},
        onSelectionChanged: (s) =>
            context.read<ThemeModeCubit>().set(s.first),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleCubit>().state;
    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(l.settingsLanguage),
      trailing: DropdownButton<String>(
        value: locale.languageCode,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'th', child: Text('ไทย')),
          DropdownMenuItem(value: 'en', child: Text('English')),
        ],
        onChanged: (v) {
          if (v == null) return;
          context.read<LocaleCubit>().set(Locale(v));
        },
      ),
    );
  }
}

class _FontPicker extends StatelessWidget {
  const _FontPicker();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleCubit>().state;
    final fontId = context.watch<FontIdCubit>().state;
    final available = FontRegistry.availableFor(locale.languageCode);

    return ListTile(
      leading: const Icon(Icons.text_fields_outlined),
      title: Text(l.settingsFont),
      trailing: DropdownButton<String>(
        value: available.any((f) => f.id == fontId)
            ? fontId
            : (available.isNotEmpty ? available.first.id : null),
        underline: const SizedBox.shrink(),
        items: available
            .map((f) => DropdownMenuItem(value: f.id, child: Text(f.family)))
            .toList(),
        onChanged: available.length > 1
            ? (v) {
                if (v != null) context.read<FontIdCubit>().set(v);
              }
            : null,
      ),
    );
  }
}
