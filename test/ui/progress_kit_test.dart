import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('segments clamp the total at 100%', () {
    final s = ProgressRow.segments(0.39, 0.09);
    expect(s.$1, 0.39);
    expect(s.$2, closeTo(0.48, 1e-9));
    expect(ProgressRow.segments(0.9, 0.4), (0.9, 1.0));
    expect(ProgressRow.segments(1.22, 0.1), (1.0, 1.0));
    expect(ProgressRow.segments(0, null), (0.0, 0.0));
  });
}
