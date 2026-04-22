import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import 'shared_preferences_provider.dart';

const List<Locale> supportedLocales = [
  Locale('en'),
  Locale('th'),
];

const Locale defaultLocale = Locale('en');

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale _load(SharedPreferences prefs) {
    final raw = prefs.getString(StorageKeys.locale);
    if (raw == null) return defaultLocale;
    final match = supportedLocales.firstWhere(
      (l) => l.languageCode == raw,
      orElse: () => defaultLocale,
    );
    return match;
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await _prefs.setString(StorageKeys.locale, locale.languageCode);
  }
}
