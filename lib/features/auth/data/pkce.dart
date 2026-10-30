import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE (RFC 7636, S256) for "เข้าสู่ระบบด้วย Telegram": the verifier stays in
/// the app until the exchange; only its hash goes out with the start.
abstract final class Pkce {
  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  /// 43–128 characters of the unreserved set; [random] is for tests.
  static String newVerifier({int length = 64, Random? random}) {
    assert(length >= 43 && length <= 128);
    final r = random ?? Random.secure();
    return String.fromCharCodes([
      for (var i = 0; i < length; i++)
        _alphabet.codeUnitAt(r.nextInt(_alphabet.length)),
    ]);
  }

  /// base64url(SHA-256(verifier)) with no padding.
  static String challengeFor(String verifier) => base64Url
      .encode(sha256.convert(ascii.encode(verifier)).bytes)
      .replaceAll('=', '');
}
