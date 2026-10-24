import 'package:chubi_pocket/core/logger/breadcrumbs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('steps: kinds, no repeat of the same step in a row, newest 50 kept', () {
    final b = Breadcrumbs.instance;
    b.page('/transactions');
    b.page('/transactions');
    b.tap('บันทึก');
    b.add('POST /transactions → 201 (153 ms)');
    expect(b.steps.map((s) => s.substring(9)), [
      'page /transactions',
      'tap "บันทึก"',
      'POST /transactions → 201 (153 ms)',
    ]);
    for (var i = 0; i < 60; i++) {
      b.page('/p$i');
    }
    expect(b.steps, hasLength(Breadcrumbs.capacity));
    expect(b.steps.last, endsWith('page /p59'));
    expect(b.text.split('\n'), hasLength(Breadcrumbs.capacity));
  });
}
