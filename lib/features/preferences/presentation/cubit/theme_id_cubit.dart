import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/theme/theme_registry.dart';

/// Holds the active theme id (e.g. `mint`, `sweet`) and persists it.
///
/// This is the canonical source of truth for which theme the app renders.
/// Phase 1+ will sync the value to `user_preferences.theme_id` on the server.
class ThemeIdCubit extends Cubit<String> {
  ThemeIdCubit(this._prefs)
      : super(
          _prefs.getString(StorageKeys.themeId) ?? ThemeRegistry.defaultThemeId,
        );

  final SharedPreferences _prefs;

  Future<void> set(String id) async {
    if (state == id) return;
    emit(id);
    await _prefs.setString(StorageKeys.themeId, id);
  }
}
