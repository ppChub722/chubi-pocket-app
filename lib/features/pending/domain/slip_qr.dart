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

  final String? bankCode;
  final String? country;

  final bool crcValid;

  static SlipQr? tryParse(String payload) {
    final top = _tlv(payload);
    if (top == null) return null;
    final inner = top['00'];
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
