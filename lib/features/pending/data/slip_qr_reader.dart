import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../domain/slip_qr.dart';

class SlipQrScan {
  const SlipQrScan({required this.raws, this.slip});

  final List<String> raws;

  final SlipQr? slip;
}

class SlipQrReader {
  const SlipQrReader();

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
