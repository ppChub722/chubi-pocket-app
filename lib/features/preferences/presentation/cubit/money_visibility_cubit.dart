import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';

/// Whether money amounts are hidden app-wide (the 👁 privacy toggle for
/// opening the app in public). `true` = hidden. Persisted locally.
class MoneyVisibilityCubit extends Cubit<bool> {
  MoneyVisibilityCubit(this._prefs)
      : super(_prefs.getBool(StorageKeys.hideAmounts) ?? false);

  final SharedPreferences _prefs;

  Future<void> toggle() => set(!state);

  Future<void> set(bool hidden) async {
    if (state == hidden) return;
    emit(hidden);
    await _prefs.setBool(StorageKeys.hideAmounts, hidden);
  }
}
