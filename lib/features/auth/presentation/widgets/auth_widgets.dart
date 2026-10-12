import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';

/// Language names by code, shared by the sign-in bar and settings.
const kLanguageNames = {'th': 'ไทย', 'en': 'English'};

/// Logo · app name · tagline. Hidden dev entrance: tap the logo 5× →
/// `/dev` (works logged out).
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({this.compact = false, super.key});

  /// Smaller logo, no tagline (register).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final size = compact ? 56.0 : 88.0;
    return Column(
      children: [
        SecretTapDetector(
          onUnlock: () => context.push('/dev'),
          child: BrandLogo(size: size),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l.appName,
          style: (compact ? textTheme.titleLarge : textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.authTagline,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// "────  หรือ  ────" between the form and other sign-in options.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(child: AppDivider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            AppLocalizations.of(context)!.authOr,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const Expanded(child: AppDivider()),
      ],
    );
  }
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
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        AppButton(
          label: l.authContinueWithGoogle,
          onPressed: onPressed,
          loading: loading,
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.large,
          expand: true,
        ),
        if (onPressed == null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: IgnorePointer(
              child: AppChip(
                label: l.authComingSoon,
                tone: AppChipTone.info,
                selected: true,
                size: ChipSize.mini,
              ),
            ),
          ),
      ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OptionMenuAnchor<String>(
          selected: code,
          onSelected: (c) => context.read<LocaleCubit>().set(Locale(c)),
          options: [
            for (final e in kLanguageNames.entries)
              SheetOption(value: e.key, label: e.value),
          ],
          builder: (context, toggle) => AppChip(
            label: kLanguageNames[code] ?? l.authLanguage,
            icon: AppIcons.language,
            trailing: AppChipTrailing.dropdown,
            onTap: toggle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButton(
          icon: dark ? AppIcons.lightMode : AppIcons.darkMode,
          tooltip: dark ? l.modeLight : l.modeDark,
          onPressed: () => context.read<ThemeModeCubit>().set(
            dark ? ThemeMode.light : ThemeMode.dark,
          ),
        ),
      ],
    );
  }
}
