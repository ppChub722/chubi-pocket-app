import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';

/// The outside apps a user links (0.4.2 1b, `/connections/{provider}`).
abstract final class ConnectionProvider {
  static const telegram = 'telegram';
  static const line = 'line';
  static const google = 'google';
}

/// The error codes of the connection calls (`error.code`).
abstract final class ConnectionErrors {
  /// LINE / Google, or the bot is off on the server (409).
  static const unavailable = 'CONNECTION_UNAVAILABLE';
  static const notLinked = 'NOT_LINKED';
  static const permissionUnavailable = 'PERMISSION_UNAVAILABLE';

  /// "Telegram ไม่ส่งรูปให้" (404 on a photo import).
  static const noPhoto = 'NO_PHOTO';

  /// The outside app failed; try again (502).
  static const providerError = 'PROVIDER_ERROR';

  /// 1b-2: no password and this is the last linked app (409 on unlink).
  static const lastLoginMethod = 'LAST_LOGIN_METHOD';

  /// PUT /users/me: the picked photo source has no photo (409).
  static const avatarSourceUnavailable = 'AVATAR_SOURCE_UNAVAILABLE';
}

/// One permission switch of a connection (in display order).
class ConnectionPermission extends Equatable {
  const ConnectionPermission({
    required this.key,
    this.available = false,
    this.on = false,
  });

  factory ConnectionPermission.fromJson(Map<String, dynamic> json) =>
      ConnectionPermission(
        key: (json['key'] as String?) ?? '',
        available: (json['available'] as bool?) ?? false,
        on: (json['on'] as bool?) ?? false,
      );

  /// chat / ask / slip / notify (Telegram, LINE); login / sheets / calendar
  /// (Google).
  final String key;

  /// false = "เร็วๆ นี้" (no switch).
  final bool available;

  /// Always false while unavailable or not linked.
  final bool on;

  @override
  List<Object?> get props => [key, available, on];
}

/// One stored picture of mine (`photo` of a connection).
class AvatarPhoto extends Equatable {
  const AvatarPhoto({
    required this.source,
    required this.url,
    required this.importedAt,
  });

  factory AvatarPhoto.fromJson(Map<String, dynamic> json) => AvatarPhoto(
    source: (json['source'] as String?) ?? '',
    url: (json['url'] as String?) ?? '',
    importedAt: DateTime.tryParse((json['imported_at'] as String?) ?? ''),
  );

  /// upload / telegram / line / google.
  final String source;

  /// `/api/v1/avatars/{id}?v={version}` (a path from the server root).
  final String url;
  final DateTime? importedAt;

  @override
  List<Object?> get props => [source, url, importedAt];
}

/// One outside app (profile → การเชื่อมต่อ, and its connection page). Its
/// name, logo, brand colour and availability all come from the server.
class Connection extends Equatable {
  const Connection({
    required this.provider,
    required this.name,
    required this.brandColor,
    required this.logoUrl,
    this.available = false,
    this.linked = false,
    this.account,
    this.linkedAt,
    this.photo,
    this.permissions = const [],
  });

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
    provider: (json['provider'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    brandColor: (json['brand_color'] as String?) ?? '',
    logoUrl: (json['logo_url'] as String?) ?? '',
    available: (json['available'] as bool?) ?? false,
    linked: (json['linked'] as bool?) ?? false,
    account: json['account'] as String?,
    linkedAt: DateTime.tryParse((json['linked_at'] as String?) ?? ''),
    photo: json['photo'] is Map
        ? AvatarPhoto.fromJson((json['photo'] as Map).cast<String, dynamic>())
        : null,
    permissions: [
      for (final p in (json['permissions'] as List?) ?? const [])
        if (p is Map) ConnectionPermission.fromJson(p.cast<String, dynamic>()),
    ],
  );

  /// telegram / line / google ([ConnectionProvider]).
  final String provider;

  /// Telegram / LINE / Google.
  final String name;

  /// `#rrggbb`.
  final String brandColor;

  /// `/api/v1/brand-logos/{provider}.png?v={n}` (public; cache by URL).
  final String logoUrl;

  /// false = "เร็วๆ นี้".
  final bool available;
  final bool linked;

  /// Linked: who it is in that app (Telegram "@username", else the first
  /// name).
  final String? account;
  final DateTime? linkedAt;

  /// The picture imported from this app (kept after unlink).
  final AvatarPhoto? photo;
  final List<ConnectionPermission> permissions;

  /// [brandColor] as a colour (bad / empty → null).
  Color? get brand {
    final hex = brandColor.startsWith('#') ? brandColor.substring(1) : '';
    final ok = hex.length == 6 && int.tryParse(hex, radix: 16) != null;
    return ok ? IconCode.hexToColor(brandColor) : null;
  }

  /// The same row after its picture was deleted (DELETE /avatars/{source}
  /// answers my profile, not the row).
  Connection withoutPhoto() => Connection(
    provider: provider,
    name: name,
    brandColor: brandColor,
    logoUrl: logoUrl,
    available: available,
    linked: linked,
    account: account,
    linkedAt: linkedAt,
    permissions: permissions,
  );

  ConnectionPermission? permission(String key) {
    for (final p in permissions) {
      if (p.key == key) return p;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    provider,
    name,
    brandColor,
    logoUrl,
    available,
    linked,
    account,
    linkedAt,
    photo,
    permissions,
  ];
}

/// POST /connections/{provider}/link: the URL to open in the outside app.
class ConnectionLinkStart extends Equatable {
  const ConnectionLinkStart({required this.url, this.expiresAt});

  factory ConnectionLinkStart.fromJson(Map<String, dynamic> json) =>
      ConnectionLinkStart(
        url: (json['url'] as String?) ?? '',
        expiresAt: DateTime.tryParse((json['expires_at'] as String?) ?? ''),
      );

  /// e.g. `https://t.me/chubiPocket_bot?start=<code>`.
  final String url;

  /// 10 minutes from the call.
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [url, expiresAt];
}
