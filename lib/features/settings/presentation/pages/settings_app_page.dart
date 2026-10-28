import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart'
    show kLanguageNames;
import '../../../preferences/presentation/cubit/font_id_cubit.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_id_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';
import '../../../users/presentation/refresh_me.dart';
import '../settings_labels.dart';

/// Settings › แอป: theme, theme mode, language, one font per language. Each
/// change shows at once and is saved to the account (PreferencesSyncCubit).
class SettingsAppPage extends StatelessWidget {
  const SettingsAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final inset = MediaQuery.paddingOf(context);
    return Scaffold(
      appBar: AppTopBar(title: l.settingsSectionApp, showBack: true),
      extendBodyBehindAppBar: true,
      body: DetailPageBody(
        // The account's copy of these values (another device may change them).
        onRefresh: () => refreshMe(context),
        topInset: inset.top + AppSpacing.lg,
        bottomInset: AppSpacing.huge + inset.bottom,
        sections: [
          (first) => SectionCard(
            first: first,
            children: const [
              _ThemeRow(),
              _ThemeModeRow(),
              _LanguageRow(),
              _FontRow(lang: 'th'),
              _FontRow(lang: 'en'),
            ],
          ),
          (first) => SectionCard(
            first: first,
            children: [
              DetailStacked(
                label: l.settingsPreview,
                child: AppText(l.settingsFontSample, role: AppTextRole.title),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
    final selected = context.watch<ThemeIdCubit>().state;
    final current = ThemeRegistry.all
        .where((t) => t.id == selected)
        .firstOrNull;
    return DetailRow(
      leading: const AppIcon(AppIcons.colorPicker),
      label: l.settingsTheme,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (current != null) ...[
            _swatches(current),
            const SizedBox(width: AppSpacing.xs),
            Text(themeName(l, current)),
          ],
        ],
      ),
      showChevron: true,
      onTap: () async {
        final picked = await showOptionSheet<String>(
          context,
          title: l.settingsTheme,
          selected: selected,
          options: [
            for (final t in ThemeRegistry.all)
              SheetOption(
                value: t.id,
                label: themeName(l, t),
                leading: _swatches(t),
              ),
          ],
        );
        if (picked != null && context.mounted) {
          context.read<ThemeIdCubit>().set(picked);
        }
      },
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = context.watch<ThemeModeCubit>().state;
    return DetailStacked(
      label: l.settingsAppearance,
      child: ThemeModeChips(
        selected: mode,
        onChanged: (m) => context.read<ThemeModeCubit>().set(m),
        lightLabel: l.modeLight,
        darkLabel: l.modeDark,
        systemLabel: l.modeSystem,
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final code = context.watch<LocaleCubit>().state.languageCode;
    return SettingDropdownRow<String>(
      leading: const AppIcon(AppIcons.language),
      label: l.settingsLanguage,
      value: kLanguageNames[code] ?? code,
      selected: code,
      // Shows at once; PreferencesSyncCubit saves it to the account.
      submits: false,
      onSelected: (picked) => context.read<LocaleCubit>().set(Locale(picked)),
      options: [
        for (final e in kLanguageNames.entries)
          SheetOption(value: e.key, label: e.value),
      ],
    );
  }
}

/// The font used while the app is in [lang].
class _FontRow extends StatefulWidget {
  const _FontRow({required this.lang});

  final String lang;

  @override
  State<_FontRow> createState() => _FontRowState();
}

class _FontRowState extends State<_FontRow> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Rebuilt by the current font too (a server value may land meanwhile).
    context.watch<FontIdCubit>();
    final cubit = context.read<FontIdCubit>();
    final available = FontRegistry.availableFor(widget.lang);
    final current = FontRegistry.byId(cubit.fontFor(widget.lang));
    final label = widget.lang == 'th'
        ? l.settingsFontThai
        : l.settingsFontEnglish;
    return DetailRow(
      leading: const AppIcon(AppIcons.font),
      label: label,
      trailing: Text(current.family),
      showChevron: available.length > 1,
      onTap: available.length < 2
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
              if (picked != null && mounted) {
                await cubit.setFor(widget.lang, picked);
                if (mounted) setState(() {});
              }
            },
    );
  }
}
