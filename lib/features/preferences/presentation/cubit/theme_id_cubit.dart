import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../ui/ui.dart';

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
