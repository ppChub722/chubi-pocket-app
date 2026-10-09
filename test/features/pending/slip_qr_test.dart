import 'package:chubi_pocket/features/pending/domain/slip_qr.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a slip payload the way banks do, with a correct CRC.
String slipPayload(String bank, String ref) {
  String tlv(String id, String v) =>
      '$id${v.length.toString().padLeft(2, '0')}$v';
  final inner = tlv('00', '000001') + tlv('01', bank) + tlv('02', ref);
  final body = '${tlv('00', inner)}${tlv('51', 'TH')}9104';
  return body + SlipQr.crc16(body);
}

void main() {
  test('crc16 matches the CCITT-FALSE check value', () {
    expect(SlipQr.crc16('123456789'), '29B1');
  });

  test('reads ref, bank and country off a slip QR', () {
    final raw = slipPayload('004', '016282103123ABC45678');
    final qr = SlipQr.tryParse(raw)!;
    expect(qr.transRef, '016282103123ABC45678');
    expect(qr.bankCode, '004');
    expect(qr.apiId, '000001');
    expect(qr.country, 'TH');
    expect(qr.crcValid, isTrue);
  });

  test('a real K PLUS slip QR (owner 2026-10-09)', () {
    final qr = SlipQr.tryParse(
      '0041000600000101030040220016282153110ATF020625102TH91042F66',
    )!;
    expect(qr.transRef, '016282153110ATF02062');
    expect(qr.bankCode, '004');
    expect(qr.country, 'TH');
    expect(qr.crcValid, isTrue);
  });

  test('a wrong CRC still gives the ref, flagged', () {
    final raw = slipPayload('014', 'REF0001');
    final bad = '${raw.substring(0, raw.length - 4)}0000';
    final qr = SlipQr.tryParse(bad)!;
    expect(qr.transRef, 'REF0001');
    expect(qr.crcValid, isFalse);
  });

  test('not a slip QR → null', () {
    // PromptPay merchant QR: tag 00 is the 2-char format version.
    expect(SlipQr.tryParse('000201010211'), isNull);
    expect(SlipQr.tryParse('https://example.com'), isNull);
    expect(SlipQr.tryParse(''), isNull);
    // Truncated TLV.
    expect(SlipQr.tryParse('0041000600'), isNull);
  });
}
