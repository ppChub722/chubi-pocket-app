import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart'
    show kLanguageNames;
import '../../../preferences/presentation/cubit/font_id_cubit.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/preferences_sync_cubit.dart';
import '../../../preferences/presentation/cubit/theme_id_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';
import '../../../users/presentation/refresh_me.dart';
import '../settings_labels.dart';

/// Settings › แอป: หน้าตา (theme, display mode), ภาษาและฟอนต์ (language, one
/// font per language) and a preview. Each change shows at once and is saved
/// to the account with one call; a failure puts the old value back
/// ([PreferencesSyncCubit.saveNow]). Read-only while offline.
class SettingsAppPage extends StatelessWidget {
  const SettingsAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.settingsSectionApp, showBack: true),
      extendBodyBehindAppBar: true,
      body: Builder(
        // Inside the Scaffold body: the inset includes the floating top bar.
        builder: (context) {
          final inset = MediaQuery.paddingOf(context);
          return DetailPageBody(
            // The account's copy of these values (another device may change
            // them).
            onRefresh: () => refreshMe(context),
            topInset: inset.top + AppSpacing.lg,
            bottomInset: AppSpacing.huge + inset.bottom,
            sections: [
              (first) => SectionCard(
                first: first,
                title: l.settingsSectionAppearance,
                children: const [_ThemeRow(), _ThemeModeRow()],
              ),
              (first) => SectionCard(
                first: first,
                title: l.settingsSectionLanguageFont,
                children: const [
                  _LanguageRow(),
                  _FontRow(lang: 'th'),
                  _FontRow(lang: 'en'),
                ],
              ),
              (first) => SectionCard(
                first: first,
                title: l.settingsPreview,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xl,
                    ),
                    child: AppText(
                      l.settingsFontSample,
                      role: AppTextRole.title,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One app preference row: shows a pick at once, saves it with one call, puts
/// the old value back (and says so) when the save fails.
Widget _livePref<T>(
  BuildContext context, {
  required T value,
  required String Function(T value) wire,
  required String key,
  required Widget Function(
    BuildContext context,
    T value,
    ValueChanged<T>? onChanged,
  )
  builder,
}) {
  final l = AppLocalizations.of(context)!;
  final sync = context.read<PreferencesSyncCubit>();
  return LiveSetting<T>(
    value: value,
    failedMessage: (_) => l.notifSettingsSaveFailed,
    save: (v) async {
      await sync.saveNow(key, wire(v));
      return true;
    },
    builder: builder,
  );
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow();

  static Widget _swatches(AppTheme t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final c in t.previewSwatch.take(2))
        Icon(Icons.circle, size: AppSpacing.lg, color: c),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _livePref<String>(
      context,
      value: context.watch<ThemeIdCubit>().state,
      wire: (id) => id,
      key: PreferencesSyncCubit.themeIdKey,
      builder: (context, value, onChanged) {
        final current = ThemeRegistry.all
            .where((t) => t.id == value)
            .firstOrNull;
        return SettingPickRow(
          leading: const AppIcon(AppIcons.colorPicker),
          label: l.settingsTheme,
          value: current == null
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _swatches(current),
                    const SizedBox(width: AppSpacing.xs),
                    Text(themeName(l, current)),
                  ],
                ),
          onTap: onChanged == null
              ? null
              : () async {
                  final picked = await showOptionSheet<String>(
                    context,
                    title: l.settingsTheme,
                    selected: value,
                    options: [
                      for (final t in ThemeRegistry.all)
                        SheetOption(
                          value: t.id,
                          label: themeName(l, t),
                          leading: _swatches(t),
                        ),
                    ],
                  );
                  if (picked != null) onChanged(picked);
                },
        );
      },
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _livePref<ThemeMode>(
      context,
      value: context.watch<ThemeModeCubit>().state,
      wire: (m) => m.name,
      key: PreferencesSyncCubit.themeModeKey,
      builder: (context, mode, onChanged) => SettingDropdownRow<ThemeMode>(
        leading: const AppIcon(AppIcons.themeMode),
        label: l.settingsAppearance,
        value: themeModeLabel(l, mode),
        selected: mode,
        onSelected: onChanged,
        options: [
          for (final m in const [
            ThemeMode.system,
            ThemeMode.light,
            ThemeMode.dark,
          ])
            SheetOption(value: m, label: themeModeLabel(l, m)),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _livePref<String>(
      context,
      value: context.watch<LocaleCubit>().state.languageCode,
      wire: (code) => code,
      key: PreferencesSyncCubit.languageKey,
      builder: (context, code, onChanged) => SettingDropdownRow<String>(
        leading: const AppIcon(AppIcons.language),
        label: l.settingsLanguage,
        value: kLanguageNames[code] ?? code,
        selected: code,
        onSelected: onChanged,
        options: [
          for (final e in kLanguageNames.entries)
            SheetOption(value: e.key, label: e.value),
        ],
      ),
    );
  }
}

/// The font used while the app is in [lang].
class _FontRow extends StatelessWidget {
  const _FontRow({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Rebuilt by the current font too (a server value may land meanwhile).
    context.watch<FontIdCubit>();
    final available = FontRegistry.availableFor(lang);
    final label = lang == 'th' ? l.settingsFontThai : l.settingsFontEnglish;
    return _livePref<String>(
      context,
      value: context.read<FontIdCubit>().fontFor(lang),
      wire: (id) => id,
      key: PreferencesSyncCubit.fontKey(lang),
      builder: (context, id, onChanged) {
        final current = FontRegistry.byId(id);
        return SettingPickRow(
          leading: const AppIcon(AppIcons.font),
          label: label,
          value: Text(current.family),
          onTap: available.length < 2 || onChanged == null
              ? null
              : () async {
                  final picked = await showOptionSheet<String>(
                    context,
                    title: label,
                    selected: current.id,
                    options: [
                      for (final f in available)
                        SheetOption(
                          value: f.id,
                          label: f.family,
                          subtitle: f.previewSample,
                          // The preview must show the font itself.
                          labelStyle: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(fontFamily: f.family),
                        ),
                    ],
                  );
                  if (picked != null) onChanged(picked);
                },
        );
      },
    );
  }
}
