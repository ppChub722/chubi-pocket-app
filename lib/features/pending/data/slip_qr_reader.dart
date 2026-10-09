import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../domain/slip_qr.dart';

/// What the QR pass found in one slip image.
class SlipQrScan {
  const SlipQrScan({required this.raws, this.slip});

  /// Every QR payload in the image, as read.
  final List<String> raws;

  /// The first one that is a slip QR, if any.
  final SlipQr? slip;
}

/// Reads the slip QR off an image file on the phone (ML Kit, on-device).
///
/// Slip import is phone-only (owner 2026-10-09): ML Kit has no web build,
/// so on web the import button is hidden — and if anything still calls
/// [read] there, it throws instead of quietly finding nothing.
class SlipQrReader {
  const SlipQrReader();

  /// False on web — hide every way into slip import.
  static bool get isSupported => !kIsWeb;

  Future<SlipQrScan> read(String path) async {
    if (!isSupported) {
      throw UnsupportedError('Slip import works in the phone app only');
    }
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final codes = await scanner.processImage(InputImage.fromFilePath(path));
      final raws = [for (final c in codes) ?c.rawValue]
        ..removeWhere((v) => v.isEmpty);
      SlipQr? slip;
      for (final r in raws) {
        slip = SlipQr.tryParse(r);
        if (slip != null) break;
      }
      return SlipQrScan(raws: raws, slip: slip);
    } finally {
      await scanner.close();
    }
  }
}
