import 'package:pp_forge_core/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a shape round-trips through json', () {
    final ic = PpForgeIconCode.fromJson(const {
      'icon': 'home',
      'shape': 'squircle',
    });
    expect(ic.shape, 'squircle');
    expect(ic.toJson()['shape'], 'squircle');
  });

  test('circle (null) is omitted so old codes stay identical', () {
    final ic = PpForgeIconCode.fromJson(const {'icon': 'home'});
    expect(ic.shape, isNull);
    expect(ic.toJson().containsKey('shape'), isFalse);
  });
}
