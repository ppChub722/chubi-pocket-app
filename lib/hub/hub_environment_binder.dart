import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pp_forge_core/hub.dart';

import '../features/preferences/presentation/cubit/locale_cubit.dart';
import '../features/preferences/presentation/cubit/theme_id_cubit.dart';
import '../features/preferences/presentation/cubit/theme_mode_cubit.dart';
import '../ui/ui.dart';

/// Hands the app's theme / mode / language cubits to the hub toolbar.
class HubEnvironmentBinder extends StatefulWidget {
  const HubEnvironmentBinder({required this.child, super.key});

  final Widget child;

  @override
  State<HubEnvironmentBinder> createState() => _HubEnvironmentBinderState();
}

class _HubEnvironmentBinderState extends State<HubEnvironmentBinder> {
  late final _AppHubEnvironment _env;

  @override
  void initState() {
    super.initState();
    _env = _AppHubEnvironment(
      context.read<ThemeIdCubit>(),
      context.read<ThemeModeCubit>(),
      context.read<LocaleCubit>(),
    );
    PpForgeHub.environment = _env;
  }

  @override
  void dispose() {
    if (PpForgeHub.environment == _env) PpForgeHub.environment = null;
    _env.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AppHubEnvironment extends ChangeNotifier implements HubEnvironment {
  _AppHubEnvironment(this._theme, this._mode, this._locale) {
    _subs = [
      _theme.stream.listen((_) => notifyListeners()),
      _mode.stream.listen((_) => notifyListeners()),
      _locale.stream.listen((_) => notifyListeners()),
    ];
  }

  final ThemeIdCubit _theme;
  final ThemeModeCubit _mode;
  final LocaleCubit _locale;
  late final List<StreamSubscription<Object?>> _subs;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  List<String> get themeIds => [for (final t in ThemeRegistry.all) t.id];
  @override
  String get themeId => _theme.state;
  @override
  void setTheme(String id) => _theme.set(id);

  @override
  ThemeMode get mode => _mode.state;
  @override
  void setMode(ThemeMode mode) => _mode.set(mode);

  @override
  List<Locale> get locales => supportedLocales;
  @override
  Locale get locale => _locale.state;
  @override
  void setLocale(Locale locale) => _locale.set(locale);
}
