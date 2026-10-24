import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ToolbarToggleState.of remembers per key', () {
    ToolbarToggleState.resetAll();
    final a = ToolbarToggleState.of('p')..toggle();
    expect(ToolbarToggleState.of('p').value, isTrue);
    expect(identical(a, ToolbarToggleState.of('p')), isTrue);
    ToolbarToggleState.resetAll();
  });
}
