import 'package:flutter/widgets.dart';

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

  final int minBuild;

  final int latestBuild;

  final String downloadUrl;
  final String? messageTh;
  final String? messageEn;

  /// [build] can't be used any more.
  bool blocks(int build) => minBuild > 0 && build < minBuild;

  bool hasUpdateFor(int build) => latestBuild > 0 && build < latestBuild;

  String? messageFor(Locale locale) => locale.languageCode == 'th'
      ? messageTh ?? messageEn
      : messageEn ?? messageTh;
}
