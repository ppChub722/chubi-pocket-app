import 'package:chubi_pocket/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never "-฿0.00" (owner 2026-10-11): anything that shows as zero prints
/// as a plain zero.
void main() {
  test('format: zero-looking amounts are plain, real ones keep their sign', () {
    final cases = <(String, String)>[
      (CurrencyFormatter.format(-0.0), '฿0.00'),
      (CurrencyFormatter.format(-0.004), '฿0.00'),
      (CurrencyFormatter.format(0.004), '฿0.00'),
      (CurrencyFormatter.format(-0.01), '-฿0.01'),
      (CurrencyFormatter.format(-0.005), '-฿0.01'),
      (CurrencyFormatter.format(-1250.5), '-฿1,250.50'),
      (CurrencyFormatter.format(1250.5), '฿1,250.50'),
      (CurrencyFormatter.format(1234.5, symbol: '¥'), '¥1,235'),
      (CurrencyFormatter.format(1234.5, symbol: '฿'), '฿1,234.50'),
    ];
    for (final (got, want) in cases) {
      expect(got, want);
    }
  });

  test('roundsToZero follows the decimals shown', () {
    final cases = <(bool, bool)>[
      (CurrencyFormatter.roundsToZero(-0.004), true),
      (CurrencyFormatter.roundsToZero(-0.005), false),
      (CurrencyFormatter.roundsToZero(-0.4, decimalDigits: 0), true),
      (CurrencyFormatter.roundsToZero(0.4, symbol: '¥'), true),
      (CurrencyFormatter.roundsToZero(0.4), false),
    ];
    for (final (i, (got, want)) in cases.indexed) {
      expect(got, want, reason: 'case $i');
    }
  });
}
