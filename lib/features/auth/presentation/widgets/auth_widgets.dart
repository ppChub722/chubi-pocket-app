import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';

const kLanguageNames = {'th': 'ไทย', 'en': 'English'};

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BrandHeader(
      name: l.appName,
      tagline: l.authTagline,
      compact: compact,
      onSecretUnlock: () => context.push('/dev'),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      OrDivider(label: AppLocalizations.of(context)!.authOr);
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({this.onPressed, this.loading = false, super.key});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SocialSignInButton(
      label: l.authContinueWithGoogle,
      comingSoonLabel: l.authComingSoon,
      onPressed: onPressed,
      loading: loading,
    );
  }
}

class AuthPrefsBar extends StatelessWidget {
  const AuthPrefsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final code = context.watch<LocaleCubit>().state.languageCode;
    final mode = context.watch<ThemeModeCubit>().state;
    final dark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return LanguageThemeBar(
      languages: kLanguageNames,
      languageCode: code,
      onLanguage: (c) => context.read<LocaleCubit>().set(Locale(c)),
      dark: dark,
      onToggleTheme: () => context.read<ThemeModeCubit>().set(
        dark ? ThemeMode.light : ThemeMode.dark,
      ),
      lightTooltip: l.modeLight,
      darkTooltip: l.modeDark,
    );
  }
}
