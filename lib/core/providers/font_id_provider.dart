import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../fonts/font_registry.dart';
import 'locale_provider.dart';
import 'shared_preferences_provider.dart';

final StateNotifierProvider<FontIdNotifier, String> fontIdProvider =
    StateNotifierProvider<FontIdNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final initialLocale = ref.read(localeProvider);
  final notifier = FontIdNotifier(prefs, initialLocale.languageCode);

  // Auto-fallback: if the locale changes and the selected font does not
  // support it, switch to the default font for the new language.
  ref.listen<Locale>(localeProvider, (_, next) {
    final current = FontRegistry.byId(notifier.currentId);
    if (!current.supports(next.languageCode)) {
      notifier.set(FontRegistry.defaultIdFor(next.languageCode));
    }
  });

  return notifier;
});

class FontIdNotifier extends StateNotifier<String> {
  FontIdNotifier(this._prefs, String initialLanguageCode)
      : super(
          _prefs.getString(StorageKeys.fontId) ??
              FontRegistry.defaultIdFor(initialLanguageCode),
        );

  final SharedPreferences _prefs;

  String get currentId => state;

  Future<void> set(String id) async {
    state = id;
    await _prefs.setString(StorageKeys.fontId, id);
  }
}
