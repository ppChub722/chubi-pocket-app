import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../theme/theme_registry.dart';
import 'shared_preferences_provider.dart';

final themeIdProvider =
    StateNotifierProvider<ThemeIdNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeIdNotifier(prefs);
});

class ThemeIdNotifier extends StateNotifier<String> {
  ThemeIdNotifier(this._prefs)
      : super(
          _prefs.getString(StorageKeys.themeId) ??
              ThemeRegistry.defaultThemeId,
        );

  final SharedPreferences _prefs;

  Future<void> set(String id) async {
    state = id;
    await _prefs.setString(StorageKeys.themeId, id);
  }
}
