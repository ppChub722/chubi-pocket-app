import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/fonts/font_preloader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _setHighRefreshRate();

  final prefs = await SharedPreferences.getInstance();
  await FontPreloader.preloadAll();

  runApp(ChubiPocketApp(prefs: prefs));
}

/// Opt in to the highest refresh rate the screen supports (e.g. 120Hz on
/// modern Android phones). No-op on web / iOS / desktop / older devices.
Future<void> _setHighRefreshRate() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {
    // OEM / hardware doesn't support it — silently fall back to default.
  }
}
