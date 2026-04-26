import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';

/// Holds the active [ThemeMode] (light / dark / system) and persists it.
///
/// Orthogonal to [ThemeIdCubit]: each themeId can render in any [ThemeMode].
class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _load(SharedPreferences prefs) {
    switch (prefs.getString(StorageKeys.themeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    if (state == mode) return;
    emit(mode);
    await _prefs.setString(StorageKeys.themeMode, mode.name);
  }

  Future<void> toggle() async {
    switch (state) {
      case ThemeMode.light:
        await set(ThemeMode.dark);
      case ThemeMode.dark:
        await set(ThemeMode.system);
      case ThemeMode.system:
        await set(ThemeMode.light);
    }
  }
}
