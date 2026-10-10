import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';

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
        Expanded(child: Divider(color: scheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            AppLocalizations.of(context)!.authOr,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Divider(color: scheme.outlineVariant)),
      ],
    );
  }
}

/// "ดำเนินการต่อด้วย Google". [onPressed] null = not wired yet → dimmed with
/// a "เร็ว ๆ นี้" badge (needs `google_sign_in` + `POST /auth/google`,
/// contract §12).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({this.onPressed, this.loading = false, super.key});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: BorderSide(color: scheme.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brand-neutral "G" mark (no trademark asset bundled yet).
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outline),
              ),
              child: Text(
                'G',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: Text(l.authContinueWithGoogle)),
            if (onPressed == null) ...[
              const SizedBox(width: AppSpacing.sm),
              AppBadge(label: l.authComingSoon, tone: Tone.info),
            ],
            if (loading) ...[
              const SizedBox(width: AppSpacing.sm),
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Language + light/dark — changeable before signing in.
class AuthPrefsBar extends StatelessWidget {
  const AuthPrefsBar({super.key});

  static const _languages = {'th': 'ไทย', 'en': 'English'};

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
            for (final e in _languages.entries)
              SheetOption(value: e.key, label: e.value),
          ],
          builder: (context, toggle) => FilterDropdownChip(
            label: l.authLanguage,
            icon: AppIcons.language,
            valueLabel: _languages[code],
            active: false,
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
