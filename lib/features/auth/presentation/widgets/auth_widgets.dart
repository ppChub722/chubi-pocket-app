import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';

// The auth pages' glue: each piece is a kit piece plus the app's strings /
// state — no styling lives here.

/// Language names by code, shared by the sign-in bar and settings.
const kLanguageNames = {'th': 'ไทย', 'en': 'English'};

/// The kit's BrandHeader with the app's name + tagline; the logo's hidden dev
/// entrance (tap 5×) opens `/dev` (works logged out).
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({this.compact = false, super.key});

  /// Smaller logo, no tagline (register).
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

/// "หรือ" divider between the form and the other sign-in options.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      OrDivider(label: AppLocalizations.of(context)!.authOr);
}

/// "ดำเนินการต่อด้วย Google". [onPressed] null = not wired yet → disabled with
/// a "เร็ว ๆ นี้" badge (needs `google_sign_in` + `POST /auth/google`,
/// contract §12).
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

/// Language + light/dark — changeable before signing in.
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
