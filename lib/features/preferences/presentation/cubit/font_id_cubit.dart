import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/fonts/font_registry.dart';
import 'locale_cubit.dart';

/// Holds the active font id (e.g. `Inter`, `IBM Plex Sans Thai`) and persists it.
///
/// Auto-fallback: when [LocaleCubit] emits a locale that the current font does
/// not support, switches to the default font for that locale.
class FontIdCubit extends Cubit<String> {
  FontIdCubit(this._prefs, LocaleCubit localeCubit)
      : super(
          _prefs.getString(StorageKeys.fontId) ??
              FontRegistry.defaultIdFor(localeCubit.state.languageCode),
        ) {
    _localeSub = localeCubit.stream.listen((locale) {
      final current = FontRegistry.byId(state);
      if (!current.supports(locale.languageCode)) {
        set(FontRegistry.defaultIdFor(locale.languageCode));
      }
    });
  }

  final SharedPreferences _prefs;
  late final StreamSubscription<Locale> _localeSub;

  Future<void> set(String id) async {
    if (state == id) return;
    emit(id);
    await _prefs.setString(StorageKeys.fontId, id);
  }

  @override
  Future<void> close() async {
    await _localeSub.cancel();
    return super.close();
  }
}
