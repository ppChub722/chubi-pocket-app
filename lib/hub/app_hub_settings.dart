import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pp_forge/hub.dart';

import '../features/preferences/presentation/cubit/locale_cubit.dart';
import '../features/preferences/presentation/cubit/theme_id_cubit.dart';
import '../features/preferences/presentation/cubit/theme_mode_cubit.dart';
import '../ui/ui.dart';

/// The portal toolbar's theme / mode / language = the app's own settings
/// (they persist): a change in the hub is a change in the app.
class AppHubSettings extends HubSettings {
  const AppHubSettings();

  @override
  List<String> get themeIds => [for (final t in ThemeRegistry.all) t.id];

  @override
  String themeId(BuildContext context) => context.watch<ThemeIdCubit>().state;

  @override
  void setThemeId(BuildContext context, String id) =>
      context.read<ThemeIdCubit>().set(id);

  @override
  ThemeMode mode(BuildContext context) => context.watch<ThemeModeCubit>().state;

  @override
  void setMode(BuildContext context, ThemeMode mode) =>
      context.read<ThemeModeCubit>().set(mode);

  @override
  List<Locale> get locales => supportedLocales;

  @override
  Locale locale(BuildContext context) => context.watch<LocaleCubit>().state;

  @override
  void setLocale(BuildContext context, Locale locale) =>
      context.read<LocaleCubit>().set(locale);
}
