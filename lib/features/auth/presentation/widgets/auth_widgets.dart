import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _telegram(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<TelegramLoginCubit>();
    final url = await cubit.start();
    if (!context.mounted) return;
    if (url == null) {
      final e = cubit.state.failure;
      if (e != null) showErrorSnackBar(context, e);
      return;
    }
    // The waiting page is there when the user comes back from Telegram.
    unawaited(context.push('/auth/telegram'));
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
    context.pop();
    cubit.reset();
    showAppSnackBar(context, l.authTelegramOpenFailed, tone: Tone.danger);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final starting = context.select<TelegramLoginCubit, bool>(
      (c) => c.state.phase == TelegramLoginPhase.starting,
    );
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
          onPressed: () => _telegram(context),
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
