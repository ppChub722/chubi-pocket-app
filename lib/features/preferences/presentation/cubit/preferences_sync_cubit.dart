import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/data/users_repository.dart';
import 'font_id_cubit.dart';
import 'locale_cubit.dart';
import 'theme_id_cubit.dart';
import 'theme_mode_cubit.dart';

/// Keeps the app preferences (theme, theme mode, language, the two fonts) on
/// the server (0.4.1-2 P3). The local cubits stay the boot cache; once signed
/// in the server wins, a key the server never got is filled from this device
/// once, and a change made here is saved with ONE `PUT /users/me`. A save that
/// fails is kept and sent again on the next sign-in / profile refresh, so the
/// server never overwrites a choice it hasn't heard yet. The state is the
/// number of keys still waiting to be saved.
class PreferencesSyncCubit extends Cubit<int> {
  PreferencesSyncCubit({
    required AuthCubit auth,
    required UsersRepository users,
    required ThemeIdCubit themeId,
    required ThemeModeCubit themeMode,
    required LocaleCubit locale,
    required FontIdCubit font,
    this.retryAfter = const Duration(seconds: 30),
  }) : _auth = auth,
       _users = users,
       _themeId = themeId,
       _themeMode = themeMode,
       _locale = locale,
       _font = font,
       super(0) {
    _subs = [
      auth.stream.listen(_onAuth),
      themeId.stream.listen((v) => _changed(_kThemeId, v)),
      themeMode.stream.listen((v) => _changed(_kThemeMode, v.name)),
      locale.stream.listen((v) => _changed(_kLanguage, v.languageCode)),
      font.changes.listen((c) => _changed(_fontKey(c.lang), c.id)),
    ];
    _onAuth(auth.state);
  }

  static const _kThemeId = 'theme_id';
  static const _kThemeMode = 'theme_mode';
  static const _kLanguage = 'language';
  static String _fontKey(String lang) => 'font_$lang';

  /// The keys [saveNow] takes.
  static const themeIdKey = _kThemeId;
  static const themeModeKey = _kThemeMode;
  static const languageKey = _kLanguage;
  static String fontKey(String lang) => _fontKey(lang);

  final AuthCubit _auth;
  final UsersRepository _users;
  final ThemeIdCubit _themeId;
  final ThemeModeCubit _themeMode;
  final LocaleCubit _locale;
  final FontIdCubit _font;
  late final List<StreamSubscription<Object?>> _subs;

  /// How long after a failed save it is tried again (also sooner, with the
  /// next change or sign-in).
  final Duration retryAfter;

  /// Keys changed here and not yet saved (key → value).
  final _pending = <String, String>{};

  /// Keys [saveNow] is saving (their own change is not queued again, and a
  /// profile refresh meanwhile doesn't put the old value back).
  final _direct = <String>{};
  bool _sending = false;
  Timer? _retry;

  User? get _user => switch (_auth.state) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };

  /// The server's value of [key] for [u].
  static String? serverValue(User u, String key) => switch (key) {
    _kThemeId => u.themeId,
    _kThemeMode => u.themeMode,
    _kLanguage => u.language,
    'font_th' => u.fontTh,
    'font_en' => u.fontEn,
    _ => null,
  };

  /// This device's value of [key].
  String _localValue(String key) => switch (key) {
    _kThemeId => _themeId.state,
    _kThemeMode => _themeMode.state.name,
    _kLanguage => _locale.state.languageCode,
    'font_th' => _font.fontFor('th'),
    'font_en' => _font.fontFor('en'),
    _ => throw ArgumentError(key),
  };

  static const _keys = [
    _kThemeId,
    _kThemeMode,
    _kLanguage,
    'font_th',
    'font_en',
  ];

  void _onAuth(AuthState s) {
    if (s is! AuthAuthenticated) return;
    final u = s.user;
    for (final key in _keys) {
      if (_pending.containsKey(key) || _direct.contains(key)) continue;
      final server = serverValue(u, key);
      if (server == null) {
        // Never saved: this device's value fills it.
        _pending[key] = _localValue(key);
      } else if (server != _localValue(key)) {
        _apply(key, server);
      }
    }
    _flush();
  }

  /// Puts a server value into its cubit (an unknown value is ignored).
  void _apply(String key, String value) {
    switch (key) {
      case _kThemeId:
        if (ThemeRegistry.all.any((t) => t.id == value)) _themeId.set(value);
      case _kThemeMode:
        final mode = ThemeMode.values.where((m) => m.name == value).firstOrNull;
        if (mode != null) _themeMode.set(mode);
      case _kLanguage:
        final loc = supportedLocales
            .where((l) => l.languageCode == value)
            .firstOrNull;
        if (loc != null) _locale.set(loc);
      case 'font_th':
        _font.setFor('th', value);
      case 'font_en':
        _font.setFor('en', value);
    }
  }

  /// A change made on the settings page (owner 2026-10-28: the same instant
  /// save + rollback as every other setting): it shows at once and is saved
  /// with ONE `PUT /users/me`; a failure puts the old value back and throws
  /// (the page says so, never the raw error). Unlike a background change, a
  /// failed one is NOT kept for a later retry.
  Future<void> saveNow(String key, String value) async {
    final old = _localValue(key);
    if (old == value || _direct.contains(key)) return;
    _direct.add(key);
    _pending.remove(key);
    try {
      _apply(key, value);
      final user = await _users.updatePreferences({key: value});
      _auth.updateUser(user);
    } catch (_) {
      _apply(key, old);
      rethrow;
    } finally {
      _direct.remove(key);
    }
  }

  void _changed(String key, String value) {
    if (_direct.contains(key)) return;
    final u = _user;
    if (u == null) return; // Signed out: the device keeps it; sent on login.
    // The server's own value coming back through the cubit: nothing to save.
    if (_pending[key] == null && serverValue(u, key) == value) return;
    _pending[key] = value;
    _flush();
  }

  Future<void> _flush() async {
    if (_sending || _pending.isEmpty || _user == null || isClosed) {
      if (!isClosed) emit(_pending.length);
      return;
    }
    _sending = true;
    _retry?.cancel();
    final batch = Map<String, String>.of(_pending);
    emit(_pending.length);
    try {
      final user = await _users.updatePreferences(batch);
      batch.forEach((k, v) {
        if (_pending[k] == v) _pending.remove(k);
      });
      _sending = false;
      _auth.updateUser(user);
    } catch (e) {
      _sending = false;
      AppLogger.instance.warn('prefs.save_failed keys=${batch.keys.join(',')}');
      if (isClosed) return;
      emit(_pending.length);
      _retry = Timer(retryAfter, _flush);
      return;
    }
    // Something changed while the save ran: send that too.
    if (_pending.isNotEmpty) {
      await _flush();
    } else if (!isClosed) {
      emit(0);
    }
  }

  @override
  Future<void> close() async {
    _retry?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
