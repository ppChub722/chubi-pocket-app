import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/boot_error_app.dart';
import 'ui/tokens/app/fonts/font_preloader.dart';
import 'core/logger/app_logger.dart';
import 'ui/ui.dart';

Future<void> main() async {
  var booted = false;
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await AppLogger.instance.init();

      // Framework errors → logger (release builds otherwise swallow them).
      FlutterError.onError = (details) {
        AppLogger.instance.error(
          'flutter.error',
          fields: {
            'exception': details.exceptionAsString(),
            'stack': details.stack?.toString(),
          },
        );
        FlutterError.presentError(details);
      };
      // Uncaught async platform errors → logger, don't crash the app.
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.instance.error(
          'platform.error',
          fields: {'exception': '$error', 'stack': '$stack'},
        );
        return true;
      };

      await _setHighRefreshRate();

      final prefs = await SharedPreferences.getInstance();

      try {
        await FontPreloader.preloadAll().timeout(const Duration(seconds: 8));
      } catch (e) {
        AppLogger.instance.warn(
          'fonts.preload_failed',
          fields: {'error': '$e', 'fallback': 'system fonts'},
        );
      }

      await BrandLogo.precache();

      runApp(ChubiPocketApp(prefs: prefs));
      booted = true;
    },
    (error, stack) {
      if (booted) {
        AppLogger.instance.error(
          'zone.uncaught',
          fields: {'exception': '$error', 'stack': '$stack'},
        );
        debugPrint('UNCAUGHT (app keeps running): $error\n$stack');
        return;
      }
      try {
        AppLogger.instance.error(
          'boot.failed',
          fields: {'exception': '$error', 'stack': '$stack'},
        );
      } catch (_) {
        /* logging must never mask the boot error */
      }
      debugPrint('BOOT FAILED: $error\n$stack');
      runApp(BootErrorApp(error: error, stackTrace: stack));
    },
  );
}

Future<void> _setHighRefreshRate() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {}
}
