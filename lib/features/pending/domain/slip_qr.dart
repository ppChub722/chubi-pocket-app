/// The mini QR printed on Thai bank transfer slips (the Bank of Thailand
/// slip-verification payload), e.g.
/// `0041000600000101030140220<20-char ref>5102TH9104<crc>`:
///
/// | tag | holds |
/// |---|---|
/// | `00` | nested: `00` API id (`000001`) · `01` sending bank code · `02` transaction ref |
/// | `51` | country (`TH`) |
/// | `91` | CRC-16/CCITT-FALSE of everything up to and including `9104` |
///
/// The transaction ref is what tells two slips apart — the same transfer
/// saved twice has the same ref (0.3.1).
class SlipQr {
  const SlipQr({
    required this.raw,
    required this.transRef,
    this.apiId,
    this.bankCode,
    this.country,
    required this.crcValid,
  });

  final String raw;
  final String transRef;
  final String? apiId;

  /// Sending bank, 3 digits (e.g. `004` KBank, `014` SCB).
  final String? bankCode;
  final String? country;

  /// The payload's own checksum matched. A bad one still gives a ref —
  /// the lab shows it so real slips can tell us whether to be strict.
  final bool crcValid;

  /// Null when [payload] isn't a slip QR (a PromptPay QR, a URL, …).
  static SlipQr? tryParse(String payload) {
    final top = _tlv(payload);
    if (top == null) return null;
    final inner = top['00'];
    // PromptPay QRs start `000201` — tag 00 is a 2-char version there.
    if (inner == null || inner.length <= 2) return null;
    final sub = _tlv(inner);
    final ref = sub?['02'];
    if (sub == null || ref == null || ref.isEmpty) return null;

    final crc = top['91'];
    final at = payload.lastIndexOf('9104');
    final crcValid =
        crc != null &&
        at >= 0 &&
        crc.toUpperCase() == crc16(payload.substring(0, at + 4)).toUpperCase();

    return SlipQr(
      raw: payload,
      transRef: ref,
      apiId: sub['00'],
      bankCode: sub['01'],
      country: top['51'],
      crcValid: crcValid,
    );
  }

  /// `id(2) len(2) value` repeated to the end, or null if it doesn't fit.
  static Map<String, String>? _tlv(String s) {
    final out = <String, String>{};
    var i = 0;
    while (i < s.length) {
      if (i + 4 > s.length) return null;
      final id = s.substring(i, i + 2);
      final len = int.tryParse(s.substring(i + 2, i + 4));
      if (len == null || i + 4 + len > s.length) return null;
      out[id] = s.substring(i + 4, i + 4 + len);
      i += 4 + len;
    }
    return out.isEmpty ? null : out;
  }

  /// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF), 4 hex digits.
  static String crc16(String s) {
    var crc = 0xFFFF;
    for (final b in s.codeUnits) {
      crc ^= b << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
