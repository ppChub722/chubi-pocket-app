import 'package:flutter/widgets.dart';

/// What the server says about app builds — `GET /app/version` `data`, and
/// the `details` of a 426 `APP_OUTDATED` (same fields, BE contract v1).
class AppVersionInfo {
  const AppVersionInfo({
    this.minBuild = 0,
    this.latestBuild = 0,
    this.downloadUrl = '',
    this.messageTh,
    this.messageEn,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    int toInt(Object? v) => switch (v) {
      final int i => i,
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    return AppVersionInfo(
      minBuild: toInt(json['min_build']),
      latestBuild: toInt(json['latest_build']),
      downloadUrl: (json['download_url'] as String?) ?? '',
      messageTh: text(json['message_th']),
      messageEn: text(json['message_en']),
    );
  }

  /// Oldest build still allowed in; 0 = the check is off.
  final int minBuild;

  /// Newest build out there; 0 = not set.
  final int latestBuild;

  /// Where to get it; empty when not set.
  final String downloadUrl;
  final String? messageTh;
  final String? messageEn;

  /// [build] can't be used any more.
  bool blocks(int build) => minBuild > 0 && build < minBuild;

  /// A newer [build] is out (but this one still works).
  bool hasUpdateFor(int build) => latestBuild > 0 && build < latestBuild;

  /// The server's own wording for [locale], if it set one (falls back to
  /// the other language before the app's default text).
  String? messageFor(Locale locale) => locale.languageCode == 'th'
      ? messageTh ?? messageEn
      : messageEn ?? messageTh;
}
