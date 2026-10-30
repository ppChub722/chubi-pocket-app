import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Gets the bytes of a server picture (the app sends its Bearer token).
typedef ServerImageFetch = Future<Uint8List> Function(Uri url);

/// How the kit loads pictures the server keeps (avatars, brand logos): the
/// app puts one scope at the top, wired to its API client. A payload's path
/// (`/api/v1/avatars/…?v=2`) resolves against [baseUrl]; [fetch] gets the
/// bytes. Without a scope a picture is a plain network image of its path.
class ServerImageScope extends InheritedWidget {
  const ServerImageScope({
    required this.baseUrl,
    required this.fetch,
    required super.child,
    super.key,
  });

  /// The API base (`https://host/api/v1`).
  final String baseUrl;
  final ServerImageFetch fetch;

  static ServerImageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServerImageScope>();

  /// [path] as a full URL: an absolute URL stays; `/…` is from the server
  /// root (the BE's `photo_url` / `logo_url`); anything else is under
  /// [baseUrl].
  static Uri resolveUrl(String baseUrl, String path) {
    final p = Uri.parse(path);
    if (p.hasScheme) return p;
    final base = Uri.parse(baseUrl);
    if (path.startsWith('/')) return base.resolveUri(p);
    final dir = base.path.endsWith('/') ? base.path : '${base.path}/';
    return base.replace(path: dir).resolveUri(p);
  }

  /// The image of [path] through the scope above [context], else a plain
  /// network image. Cached by the full URL (its `?v=` included).
  static ImageProvider providerOf(BuildContext context, String path) {
    final scope = maybeOf(context);
    if (scope == null) return NetworkImage(path);
    return ServerImageProvider(resolveUrl(scope.baseUrl, path), scope.fetch);
  }

  @override
  bool updateShouldNotify(ServerImageScope oldWidget) =>
      baseUrl != oldWidget.baseUrl || fetch != oldWidget.fetch;
}

/// One server picture, keyed by its URL alone (the image cache keeps one
/// copy per URL; a new `?v=` is a new picture).
@immutable
class ServerImageProvider extends ImageProvider<ServerImageProvider> {
  const ServerImageProvider(this.url, this.fetch);

  final Uri url;
  final ServerImageFetch fetch;

  @override
  Future<ServerImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<ServerImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    ServerImageProvider key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(key, decode),
    scale: 1,
    debugLabel: '$url',
  );

  static Future<ui.Codec> _load(
    ServerImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.fetch(key.url);
    if (bytes.isEmpty) throw StateError('empty picture: ${key.url}');
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is ServerImageProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'ServerImageProvider($url)';
}
