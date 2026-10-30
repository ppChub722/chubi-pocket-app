import 'dart:async';

import 'package:flutter/widgets.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = BrandLogo.standardSize, super.key});

  /// The one size of the logo on a brand screen (see BrandScreen).
  static const standardSize = 88.0;

  static const _asset = AssetImage('assets/icon/logo.png');

  final double size;

  /// Decodes the logo into the image cache before the first frame, so the
  /// splash shows it on that frame instead of popping in after the native
  /// launch screen is gone.
  static Future<void> precache() async {
    final done = Completer<void>();
    final stream = _asset.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
      onError: (_, _) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image(
        image: _asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      ),
    );
  }
}
