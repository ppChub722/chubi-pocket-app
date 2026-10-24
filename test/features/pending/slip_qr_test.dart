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

  test('a wrong CRC still gives the ref, flagged', () {
    final raw = slipPayload('014', 'REF0001');
    final bad = '${raw.substring(0, raw.length - 4)}0000';
    final qr = SlipQr.tryParse(bad)!;
    expect(qr.transRef, 'REF0001');
    expect(qr.crcValid, isFalse);
  });

  test('reads a slip QR: ref, bank, country; anything else is null', () {
    for (final c in [
      (
        name: 'built payload',
        raw: slipPayload('004', '016282103123ABC45678'),
        ref: '016282103123ABC45678',
        bank: '004',
      ),
      (
        name: 'a real K PLUS slip QR (owner 2026-10-09)',
        raw: '0041000600000101030040220016282153110ATF020625102TH91042F66',
        ref: '016282153110ATF02062',
        bank: '004',
      ),
    ]) {
      final qr = SlipQr.tryParse(c.raw)!;
      expect(qr.transRef, c.ref, reason: c.name);
      expect(qr.bankCode, c.bank, reason: c.name);
      expect(qr.country, 'TH', reason: c.name);
      expect(qr.crcValid, isTrue, reason: c.name);
    }
    expect(
      SlipQr.tryParse(slipPayload('004', '016282103123ABC45678'))!.apiId,
      '000001',
    );
    for (final raw in [
      '000201010211',
      'https://example.com',
      '',
      '0041000600',
    ]) {
      expect(SlipQr.tryParse(raw), isNull, reason: raw);
    }
  });
}
