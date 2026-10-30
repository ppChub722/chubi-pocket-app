import 'package:chubi_pocket/ui/domain/connections/connection_link_button.dart';
import 'package:chubi_pocket/ui/domain/icons/icon_maker_sheet.dart';
import 'package:chubi_pocket/ui/domain/icons/icon_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('white label reads on every brand fill (>= 4.5:1)', () {
    for (final brand in const [
      Color(0xFF26A5E4), // Telegram blue, ~2.6:1 with white as is
      Color(0xFF06C755), // LINE green
      Color(0xFF4285F4), // Google blue
      Color(0xFFFFEB3B), // a very light brand
    ]) {
      final fill = ConnectionLinkButton.fillFor(brand);
      expect(
        _ratio(fill, ConnectionLinkButton.labelColor),
        greaterThanOrEqualTo(ConnectionLinkButton.minContrast),
        reason: '$brand -> $fill',
      );
    }
  });

  test('a brand that already reads is kept as it is', () {
    const dark = Color(0xFF1B5E20);
    expect(ConnectionLinkButton.fillFor(dark), dark);
  });

  test('rainbow has no pickable colours, a solid background has', () {
    expect(
      backgroundHasNoPickableColors(IconType.userProfile, 'rainbow'),
      isTrue,
    );
    expect(
      backgroundHasNoPickableColors(IconType.userProfile, 'solid'),
      isFalse,
    );
    expect(backgroundHasNoPickableColors(IconType.userProfile, null), isFalse);
  });
}
