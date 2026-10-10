class StorageKeys {
  const StorageKeys._();

  static const String themeId = 'pref.theme_id';
  static const String themeMode = 'pref.theme_mode';
  static const String fontId = 'pref.font_id';
  static const String locale = 'pref.locale';
  static const String hideAmounts = 'pref.hide_amounts';

  /// The wallet last used to record money (quick create, settle a debt) —
  /// the next one starts there.
  static const String lastAccountId = 'quick.last_account_id';
}
