import 'package:chubi_pocket/shared/widgets/inputs/amount_field.dart';
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
  group('ThousandsInputFormatter', () {
    test('groups thousands', () {
      expect(_type(ThousandsInputFormatter(), '123', '1234').text, '1,234');
    });

    test('rejects a minus unless allowNegative', () {
      expect(_type(ThousandsInputFormatter(), '12', '-12').text, '12');
    });

    test('keeps a leading minus and groups the magnitude', () {
      final f = ThousandsInputFormatter(allowNegative: true);
      expect(_type(f, '-123', '-1234').text, '-1,234');
      expect(_type(f, '-1,234', '-1,234.5').text, '-1,234.5');
    });

    test('rejects bad input after the minus', () {
      final f = ThousandsInputFormatter(allowNegative: true);
      expect(_type(f, '-12', '-12a').text, '-12');
    });
  });

  test('AmountField.parse reads the sign', () {
    expect(AmountField.parse('-1,234.50'), -1234.5);
    expect(AmountField.parse('1,234'), 1234);
  });
}
