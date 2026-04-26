import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_radius.dart';
import '../core/constants/app_spacing.dart';
import '../core/fonts/font_registry.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/theme_registry.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../features/preferences/presentation/cubit/font_id_cubit.dart';
import '../features/preferences/presentation/cubit/locale_cubit.dart';
import '../features/preferences/presentation/cubit/theme_id_cubit.dart';
import '../features/preferences/presentation/cubit/theme_mode_cubit.dart';
import '../l10n/gen/app_localizations.dart';

class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<ThemeIdCubit>().state;
    final themeMode = context.watch<ThemeModeCubit>().state;
    final fontId = context.watch<FontIdCubit>().state;
    final locale = context.watch<LocaleCubit>().state;
    final currentFont = FontRegistry.byId(fontId);

    final availableFonts = FontRegistry.availableFor(locale.languageCode);

    final colors = Theme.of(context).extension<AppColors>()!;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.previewTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Section(
            title: l.sectionTheme,
            child: Wrap(
              spacing: AppSpacing.sm,
              children: ThemeRegistry.all.map((t) {
                final selected = t.id == themeId;
                return ChoiceChip(
                  label: Text(t.id),
                  selected: selected,
                  avatar: _SwatchDot(color: t.previewSwatch.first),
                  onSelected: (_) => context.read<ThemeIdCubit>().set(t.id),
                );
              }).toList(),
            ),
          ),
          _Section(
            title: l.sectionMode,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l.modeLight),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l.modeDark),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l.modeSystem),
                  icon: const Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  context.read<ThemeModeCubit>().set(s.first),
            ),
          ),
          _Section(
            title: l.sectionLanguage,
            child: Wrap(
              spacing: AppSpacing.sm,
              children: supportedLocales.map((loc) {
                final selected = loc.languageCode == locale.languageCode;
                return ChoiceChip(
                  label: Text(loc.languageCode.toUpperCase()),
                  selected: selected,
                  onSelected: (_) => context.read<LocaleCubit>().set(loc),
                );
              }).toList(),
            ),
          ),
          _Section(
            title: l.sectionFont,
            subtitle: l.fontsAvailableFor(
              availableFonts.length,
              locale.languageCode,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: availableFonts.map((f) {
                final selected = f.id == fontId;
                return ChoiceChip(
                  label: Text(f.family),
                  selected: selected,
                  onSelected: (_) => context.read<FontIdCubit>().set(f.id),
                );
              }).toList(),
            ),
          ),
          _Section(
            title: l.sectionCurrentSelection,
            child: Text(
              'theme:  $themeId\n'
              'mode:   ${themeMode.name}\n'
              'font:   ${currentFont.family}  (supports: ${currentFont.supportedLanguages.join(', ')})\n'
              'locale: ${locale.languageCode}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _Section(
            title: l.sectionTypographySamples,
            child: _TypographySamples(sample: currentFont.previewSample),
          ),
          _Section(
            title: l.sectionSemanticColors,
            child: _ColorSwatches(colors: colors),
          ),
          _Section(
            title: l.sectionFormatters,
            child: _FormatterSamples(localeCode: locale.languageCode),
          ),
          _Section(
            title: l.sectionControls,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Elevated'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Text button'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
              ],
            ),
          ),
          _Section(
            title: l.sectionInput,
            child: TextField(
              decoration: InputDecoration(
                labelText: l.amountLabel,
                hintText: l.amountHint,
              ),
            ),
          ),
          _Section(
            title: l.sectionCard,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.monthlyBalance,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CurrencyFormatter.format(12450.75,
                          locale: locale.toString()),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TypographySamples extends StatelessWidget {
  const _TypographySamples({required this.sample});
  final String sample;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sample, style: t.displaySmall),
        Text(sample, style: t.headlineMedium),
        Text(sample, style: t.titleLarge),
        Text(sample, style: t.bodyLarge),
        Text(sample, style: t.bodyMedium),
        Text(sample, style: t.labelSmall),
      ],
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, Color, Color)>[
      ('primary', colors.primary, colors.onPrimary),
      ('secondary', colors.secondary, colors.onSecondary),
      ('surface', colors.surface, colors.onSurface),
      ('surfaceVariant', colors.surfaceVariant, colors.onSurfaceVariant),
      ('income', colors.income, colors.onIncome),
      ('expense', colors.expense, colors.onExpense),
      ('warning', colors.warning, colors.onWarning),
      ('info', colors.info, colors.onInfo),
      ('success', colors.success, colors.onSuccess),
      ('error', colors.error, colors.onError),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: entries
          .map((e) => Container(
                width: 110,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: e.$2,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: colors.outlineSoft),
                ),
                child: Text(
                  e.$1,
                  style: TextStyle(color: e.$3, fontSize: 12),
                ),
              ))
          .toList(),
    );
  }
}

class _FormatterSamples extends StatelessWidget {
  const _FormatterSamples({required this.localeCode});
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('currency: ${CurrencyFormatter.format(1234.56, locale: localeCode)}',
            style: style),
        Text(
            'compact:  ${CurrencyFormatter.compact(1234567, locale: localeCode)}',
            style: style),
        Text('date short:  ${DateFormatter.short(now, locale: localeCode)}',
            style: style),
        Text('date medium: ${DateFormatter.medium(now, locale: localeCode)}',
            style: style),
        Text('time:        ${DateFormatter.time(now, locale: localeCode)}',
            style: style),
      ],
    );
  }
}
