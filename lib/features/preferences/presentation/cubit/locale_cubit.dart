import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';

const List<Locale> supportedLocales = [
  Locale('th'),
  Locale('en'),
];

const Locale defaultLocale = Locale('th');

/// Holds the active [Locale] and persists it. Defaults to Thai per design lock.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale _load(SharedPreferences prefs) {
    final raw = prefs.getString(StorageKeys.locale);
    if (raw == null) return defaultLocale;
    return supportedLocales.firstWhere(
      (l) => l.languageCode == raw,
      orElse: () => defaultLocale,
    );
  }

  Future<void> set(Locale locale) async {
    if (state == locale) return;
    emit(locale);
    await _prefs.setString(StorageKeys.locale, locale.languageCode);
  }
}
