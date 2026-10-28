import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import 'locale_cubit.dart';
import '../../../../ui/ui.dart';

/// One font per language (settings "ฟอนต์ภาษาไทย" / "ฟอนต์ภาษาอังกฤษ"); the
/// state is the font of the CURRENT language, the one the app draws with.
class FontIdCubit extends Cubit<String> {
  FontIdCubit(this._prefs, LocaleCubit localeCubit)
    : _lang = localeCubit.state.languageCode,
      super(_load(_prefs, localeCubit.state.languageCode)) {
    _localeSub = localeCubit.stream.listen((locale) {
      _lang = locale.languageCode;
      emit(fontFor(_lang));
    });
  }

  final SharedPreferences _prefs;
  String _lang;
  late final StreamSubscription<Locale> _localeSub;
  final _changes = StreamController<({String lang, String id})>.broadcast();

  /// Every font set for a language (any language, not only the current one).
  Stream<({String lang, String id})> get changes => _changes.stream;

  static String _key(String lang) => '${StorageKeys.fontId}.$lang';

  static String _load(SharedPreferences prefs, String lang) {
    final saved =
        prefs.getString(_key(lang)) ?? prefs.getString(StorageKeys.fontId);
    if (saved != null && FontRegistry.byId(saved).supports(lang)) return saved;
    return FontRegistry.defaultIdFor(lang);
  }

  /// The font picked for [lang] (its default when none or not for [lang]).
  String fontFor(String lang) => _load(_prefs, lang);

  /// Sets the font of [lang]; the app redraws when [lang] is the current one.
  Future<void> setFor(String lang, String id) async {
    if (!FontRegistry.byId(id).supports(lang) || fontFor(lang) == id) return;
    await _prefs.setString(_key(lang), id);
    if (lang == _lang && state != id) emit(id);
    _changes.add((lang: lang, id: id));
  }

  /// Sets the font of the current language.
  Future<void> set(String id) => setFor(_lang, id);

  @override
  Future<void> close() async {
    await _localeSub.cancel();
    await _changes.close();
    return super.close();
  }
}
