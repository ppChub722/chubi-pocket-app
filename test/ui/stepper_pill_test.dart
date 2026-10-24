import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startOf / shift: week starts Monday, month and year roll over', () {
    // 2026-10-14 is a Wednesday.
    expect(
      StepperPill.startOf(StepperUnit.week, DateTime(2026, 10, 14)),
      DateTime(2026, 10, 12),
    );
    expect(
      StepperPill.shift(StepperUnit.week, DateTime(2026, 12, 28), 1),
      DateTime(2027, 1, 4),
    );
    expect(
      StepperPill.shift(StepperUnit.month, DateTime(2026, 1), -1),
      DateTime(2025, 12),
    );
    expect(
      StepperPill.shift(StepperUnit.year, DateTime(2026), 1),
      DateTime(2027),
    );
  });
}
