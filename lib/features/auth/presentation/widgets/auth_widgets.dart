import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';
import '../cubit/telegram_login_cubit.dart';

const kLanguageNames = {'th': 'ไทย', 'en': 'English'};

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BrandHeader(
      name: l.appName,
      tagline: l.authTagline,
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

/// The outside sign-ins under "หรือ": Telegram works, Google / LINE are
/// "เร็ว ๆ นี้" (0.4.3). The logos are the BE's public brand logos.
class AuthSocialCards extends StatelessWidget {
  const AuthSocialCards({super.key});

  static const _logos = '/api/v1/brand-logos';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final starting = context.select<TelegramLoginCubit, bool>(
      (c) => c.state.busy,
    );
    return BlocListener<TelegramLoginCubit, TelegramLoginState>(
      listenWhen: (a, b) => a.failureId != b.failureId,
      listener: (context, s) {
        final e = s.failure;
        if (s.openFailed) {
          showAppSnackBar(context, l.authTelegramOpenFailed, tone: Tone.danger);
        } else if (e != null) {
          showErrorSnackBar(context, e);
        }
      },
      child: _cards(context, l, starting),
    );
  }

  Widget _cards(BuildContext context, AppLocalizations l, bool starting) {
    return SocialSignInCards(
      comingSoonLabel: l.authComingSoon,
      options: [
        SocialSignInOption(
          label: 'Telegram',
          logo: const ProviderLogo(
            url: '$_logos/telegram.png?v=1',
            name: 'Telegram',
            size: 40,
          ),
          loading: starting,
          onPressed: () => context.read<TelegramLoginCubit>().signIn(),
        ),
        const SocialSignInOption(
          label: 'Google',
          logo: ProviderLogo(
            url: '$_logos/google.png?v=1',
            name: 'Google',
            size: 40,
          ),
        ),
        const SocialSignInOption(
          label: 'LINE',
          logo: ProviderLogo(
            url: '$_logos/line.png?v=1',
            name: 'LINE',
            size: 40,
          ),
        ),
      ],
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
