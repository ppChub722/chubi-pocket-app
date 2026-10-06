import 'package:chubi_pocket/shared/icon_maker/icon_code.dart';
import 'package:chubi_pocket/shared/icon_maker/icon_shape.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IconShape', () {
    test('null / unknown id falls back to circle', () {
      expect(IconShape.fromId(null), IconShape.circle);
      expect(IconShape.fromId('triangle'), IconShape.circle);
      expect(IconShape.fromId('leaf'), IconShape.leaf);
    });

    test('circle radius is half the size (renders exactly as before)', () {
      expect(IconShape.circle.radius(40),
          const BorderRadius.all(Radius.circular(20)));
    });
  });

  group('IconCode.shape json', () {
    test('round-trips a shape', () {
      final ic = IconCode.fromJson(const {'icon': 'home', 'shape': 'squircle'});
      expect(ic.shape, 'squircle');
      expect(ic.toJson()['shape'], 'squircle');
    });

    test('circle (null) is omitted so old codes stay identical', () {
      final ic = IconCode.fromJson(const {'icon': 'home'});
      expect(ic.shape, isNull);
      expect(ic.toJson().containsKey('shape'), isFalse);
    });

    test('shape takes part in equality', () {
      const a = IconCode(icon: 'home');
      const b = IconCode(icon: 'home', shape: 'leaf');
      expect(a == b, isFalse);
    });
  });
}
