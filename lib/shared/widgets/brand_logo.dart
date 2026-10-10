import 'dart:async';

import 'package:flutter/widgets.dart';

/// The app's logo mark (assets/icon/logo.png) — splash, auth header, the
/// app-version gate.
///
/// The art has black corners, not transparent ones, so it's clipped to its
/// rounded square here: 24% radius, the same cut-out the native launch
/// screen uses (assets/splash/), so the hand-off keeps its shape.
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = BrandLogo.splashSize, super.key});

  /// The launch size: the native launch screen draws the logo at exactly
  /// this many dp, centred, and `SplashPage` puts it on the same spot.
  static const splashSize = 128.0;

  static const _asset = AssetImage('assets/icon/logo.png');

  final double size;

  /// Decodes the logo into the image cache before the first frame, so the
  /// splash shows it on that frame instead of popping in after the native
  /// launch screen is gone. Call before `runApp`; never throws.
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
