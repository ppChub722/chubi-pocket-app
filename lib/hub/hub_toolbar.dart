import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/preferences/presentation/cubit/locale_cubit.dart';
import '../features/preferences/presentation/cubit/theme_id_cubit.dart';
import '../features/preferences/presentation/cubit/theme_mode_cubit.dart';
import '../ui/ui.dart';

/// The text scales a UI page can be previewed at.
const hubTextScales = [0.85, 1.0, 1.15, 1.3, 1.6];

/// The UI toolbar (owner 2026-10-12): on every UI page of the hub, switch the
/// theme, light / dark / system, the language and the text scale, and see the
/// piece change at once. Theme / mode / language are the app's own settings
/// (they persist); the text scale only affects the page being viewed.
class HubToolbar extends StatelessWidget {
  const HubToolbar({
    required this.textScale,
    required this.onTextScale,
    super.key,
  });

  final double textScale;
  final ValueChanged<double> onTextScale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeId = context.watch<ThemeIdCubit>().state;
    final mode = context.watch<ThemeModeCubit>().state;
    final locale = context.watch<LocaleCubit>().state;

    Widget group(String label, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.xs),
          for (final c in chips) ...[c, const SizedBox(width: AppSpacing.xs)],
        ],
      ),
    );

    return Material(
      color: scheme.surfaceContainerHigh,
      child: SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          children: [
            Center(
              child: group('Theme', [
                for (final t in ThemeRegistry.all)
                  AppChip(
                    label: t.id,
                    size: ChipSize.chip,
                    selected: t.id == themeId,
                    onTap: () => context.read<ThemeIdCubit>().set(t.id),
                  ),
              ]),
            ),
            Center(
              child: group('Mode', [
                for (final (m, icon) in const [
                  (ThemeMode.light, AppIcons.lightMode),
                  (ThemeMode.dark, AppIcons.darkMode),
                  (ThemeMode.system, AppIcons.systemMode),
                ])
                  AppChip(
                    label: m.name,
                    icon: icon,
                    size: ChipSize.chip,
                    selected: m == mode,
                    onTap: () => context.read<ThemeModeCubit>().set(m),
                  ),
              ]),
            ),
            Center(
              child: group('Language', [
                for (final loc in supportedLocales)
                  AppChip(
                    label: loc.languageCode.toUpperCase(),
                    size: ChipSize.chip,
                    selected: loc.languageCode == locale.languageCode,
                    onTap: () => context.read<LocaleCubit>().set(loc),
                  ),
              ]),
            ),
            Center(
              child: group('Text', [
                for (final s in hubTextScales)
                  AppChip(
                    label: '${(s * 100).round()}%',
                    size: ChipSize.chip,
                    selected: s == textScale,
                    onTap: () => onTextScale(s),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
