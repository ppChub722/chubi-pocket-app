import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/boot_error_app.dart';
import 'core/fonts/font_preloader.dart';
import 'core/logger/app_logger.dart';
import 'shared/widgets/brand_logo.dart';

Future<void> main() async {
  // Boot guard: anything that escapes below lands in the zone handler —
  // logged + surfaced as a visible error screen instead of the infinite
  // white screen we shipped once (missing INTERNET permission killed the
  // font preload before runApp; nobody could see why).
  //
  // Only BOOT failures get that screen. Once the app is up, the zone keeps
  // catching every stray async error for its whole life — those are
  // logged and the app carries on (a late 401 must never replace the
  // running app with "Failed to start", QA S1 2026-10-11).
  var booted = false;
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Logger first — every line below this should be capturable. The
      // active config is resolved from APP_ENV / dart-defines; defaults
      // mirror the BE plan (debug+bodies in local, info in staging,
      // warn-only in prod).
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

      // Font preload is a nice-to-have — never let it block or kill boot
      // (it downloads from the network via google_fonts; offline/slow
      // devices fall back to system fonts and the app must still open).
      try {
        await FontPreloader.preloadAll().timeout(const Duration(seconds: 8));
      } catch (e) {
        AppLogger.instance.warn(
          'fonts.preload_failed',
          fields: {'error': '$e', 'fallback': 'system fonts'},
        );
      }

      // The splash's logo, decoded before the first frame — the native
      // launch screen hands off to it with no blank beat.
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
      // Best-effort logging — the logger may or may not be up yet.
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
