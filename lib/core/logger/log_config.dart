import 'package:flutter/foundation.dart';

import 'log_entry.dart';

/// Application environment. Set at build time via dart-define:
///
///   flutter run --dart-define=APP_ENV=staging
///
/// Default resolution (when no dart-define is given) follows the Flutter
/// build mode:
///   debug   → local
///   profile → staging
///   release → prod
///
/// Three values mirror the BE plan's three lifecycle phases (closed
/// beta / wider beta / production — see
/// chubi-pocket-docs/engineering/logging-plan.md §Phase strategy).
enum AppEnv {
  local,
  staging,
  prod;

  String get wire => name;

  static AppEnv? _cached;

  /// Resolve once per process. Subsequent calls return the cached value.
  static AppEnv resolve() {
    final cached = _cached;
    if (cached != null) return cached;
    const raw = String.fromEnvironment('APP_ENV', defaultValue: '');
    AppEnv resolved;
    switch (raw.toLowerCase()) {
      case 'local':
        resolved = AppEnv.local;
      case 'staging':
        resolved = AppEnv.staging;
      case 'prod':
      case 'production':
        resolved = AppEnv.prod;
      default:
        // No explicit override → derive from build mode.
        if (kDebugMode) {
          resolved = AppEnv.local;
        } else if (kProfileMode) {
          resolved = AppEnv.staging;
        } else {
          resolved = AppEnv.prod;
        }
    }
    _cached = resolved;
    return resolved;
  }
}

/// Logger tunables resolved per environment, with per-knob dart-define
/// overrides for fine-tuning without changing env. Pattern matches the
/// BE plan: "Switching phase = edit `.env` + restart. No code changes."
///
/// Defaults align with logging-plan.md §Phase strategy:
///   local   → minLevel=debug, logBodies=true,  fileSink=true
///   staging → minLevel=info,  logBodies=false, fileSink=true
///   prod    → minLevel=warn,  logBodies=false, fileSink=true
///
/// Per-knob dart-defines (override defaults; same value for any env):
///   --dart-define=LOG_LEVEL=debug|info|warn|error|critical
///   --dart-define=LOG_BODIES=true|false
///   --dart-define=LOG_FILE=true|false
class LogConfig {
  const LogConfig({
    required this.env,
    required this.minLevel,
    required this.logBodies,
    required this.fileSink,
  });

  final AppEnv env;
  final LogLevel minLevel;
  final bool logBodies;
  final bool fileSink;

  /// Build the active config from the current process env + dart-defines.
  /// Cached on AppLogger after first init; the values are immutable for
  /// the lifetime of the process.
  factory LogConfig.fromEnv() {
    final env = AppEnv.resolve();

    final defaults = switch (env) {
      AppEnv.local => const _Defaults(
          minLevel: LogLevel.debug,
          logBodies: true,
          fileSink: true,
        ),
      AppEnv.staging => const _Defaults(
          minLevel: LogLevel.info,
          logBodies: false,
          fileSink: true,
        ),
      AppEnv.prod => const _Defaults(
          minLevel: LogLevel.warn,
          logBodies: false,
          fileSink: true,
        ),
    };

    const lvlRaw = String.fromEnvironment('LOG_LEVEL', defaultValue: '');
    const bodiesRaw = String.fromEnvironment('LOG_BODIES', defaultValue: '');
    const fileRaw = String.fromEnvironment('LOG_FILE', defaultValue: '');

    return LogConfig(
      env: env,
      minLevel: LogLevel.parse(lvlRaw) ?? defaults.minLevel,
      logBodies: _parseBool(bodiesRaw) ?? defaults.logBodies,
      fileSink: _parseBool(fileRaw) ?? defaults.fileSink,
    );
  }

  static bool? _parseBool(String raw) {
    switch (raw.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
      default:
        return null;
    }
  }

  @override
  String toString() =>
      'LogConfig(env=${env.wire} min=${minLevel.wire} bodies=$logBodies file=$fileSink)';
}

class _Defaults {
  const _Defaults({
    required this.minLevel,
    required this.logBodies,
    required this.fileSink,
  });
  final LogLevel minLevel;
  final bool logBodies;
  final bool fileSink;
}
