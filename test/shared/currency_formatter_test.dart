import 'package:chubi_pocket/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never "-฿0.00" (owner 2026-10-11): anything that shows as zero prints
/// as a plain zero.
void main() {
  test('-0.0 and tiny negatives print as ฿0.00', () {
    expect(CurrencyFormatter.format(-0.0), '฿0.00');
    expect(CurrencyFormatter.format(-0.004), '฿0.00');
    expect(CurrencyFormatter.format(0.004), '฿0.00');
  });

  test('real amounts keep their sign', () {
    expect(CurrencyFormatter.format(-0.01), '-฿0.01');
    expect(CurrencyFormatter.format(-0.005), '-฿0.01'); // half away from 0
    expect(CurrencyFormatter.format(-1250.5), '-฿1,250.50');
    expect(CurrencyFormatter.format(1250.5), '฿1,250.50');
  });

  test('roundsToZero follows the decimals shown', () {
    expect(CurrencyFormatter.roundsToZero(-0.004), isTrue);
    expect(CurrencyFormatter.roundsToZero(-0.005), isFalse);
    expect(CurrencyFormatter.roundsToZero(-0.4, decimalDigits: 0), isTrue);
  });
}
