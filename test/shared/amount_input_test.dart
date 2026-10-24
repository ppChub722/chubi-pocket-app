import 'package:chubi_pocket/ui/molecules/amount_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _type(ThousandsInputFormatter f, String old, String next) =>
    f.formatEditUpdate(
      TextEditingValue(
        text: old,
        selection: TextSelection.collapsed(offset: old.length),
      ),
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      ),
    );

void main() {
  test('ThousandsInputFormatter: grouping, minus, bad input', () {
    final plain = ThousandsInputFormatter();
    final signed = ThousandsInputFormatter(allowNegative: true);
    final cases = <(String, ThousandsInputFormatter, String, String, String)>[
      ('groups thousands', plain, '123', '1234', '1,234'),
      ('rejects a minus unless allowNegative', plain, '12', '-12', '12'),
      (
        'keeps a leading minus, groups the magnitude',
        signed,
        '-123',
        '-1234',
        '-1,234',
      ),
      ('keeps decimals', signed, '-1,234', '-1,234.5', '-1,234.5'),
      ('rejects bad input after the minus', signed, '-12', '-12a', '-12'),
    ];
    for (final (name, f, old, next, want) in cases) {
      expect(_type(f, old, next).text, want, reason: name);
    }
  });

  test('AmountInput.parse reads the sign', () {
    expect(AmountInput.parse('-1,234.50'), -1234.5);
    expect(AmountInput.parse('1,234'), 1234);
  });
}
