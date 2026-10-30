import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The icon maker's colour-only mode values (0.4.2 1b).
void main() {
  test('from saved settings: slots 1–3, the rest kept, ring read', () {
    final d = AvatarColorsDraft.from(const [
      '#1',
      '#2',
      '#3',
      '#4',
    ], const AvatarBorder(style: 'thick', colors: ['#F06292']));
    expect(d.slots, ['#1', '#2', '#3']);
    expect(d.extra, ['#4']);
    expect(d.borderStyle, AvatarBorderStyle.thick);
    expect(d.borderColor, '#F06292');
    expect(d.colors, ['#1', '#2', '#3', '#4']);
  });

  test('empty settings: three unset slots, no ring', () {
    final d = AvatarColorsDraft.from(const [], null);
    expect(d.slots, ['', '', '']);
    expect(d.hasBorder, isFalse);
    expect(d.border, isNull);
    expect(d.colors, isEmpty);
    expect(d.profileColors, isEmpty);
  });

  test('an unknown / "none" ring style reads as thin / none', () {
    expect(
      AvatarColorsDraft.from(
        const [],
        const AvatarBorder(style: 'solid', colors: ['#000000']),
      ).borderStyle,
      AvatarBorderStyle.thin,
    );
    expect(
      AvatarColorsDraft.from(
        const [],
        const AvatarBorder(style: 'none'),
      ).borderStyle,
      AvatarBorderStyle.none,
    );
  });

  test('an unset middle slot is just missing (as the BE keeps it)', () {
    final d = AvatarColorsDraft.from(
      const [],
      null,
    ).withSlot(0, '#A').withSlot(2, '#C');
    expect(d.slots, ['#A', '', '#C']);
    expect(d.colors, ['#A', '#C']);
    expect(d.withSlot(0, '').colors, ['#C']);
    expect(d.withSlot(5, '#X'), d, reason: 'out of range: no change');
  });

  test('a ring turned on with no colour takes colour 1, else a theme one', () {
    final withColour = AvatarColorsDraft.from(const [
      '#A',
    ], null).withBorderStyle(AvatarBorderStyle.thin);
    expect(
      withColour.border,
      const AvatarBorder(style: 'thin', colors: ['#A']),
    );
    final bare = AvatarColorsDraft.from(
      const [],
      null,
    ).withBorderStyle(AvatarBorderStyle.dashed);
    expect(bare.borderColor, AvatarColorsDraft.defaultBorderColor);
    expect(
      withColour.withBorderStyle('rainbow'),
      withColour,
      reason: 'unknown styles are ignored',
    );
  });

  test('ring off keeps its colour for later, sends no border', () {
    final d = AvatarColorsDraft.from(
      const ['#A'],
      const AvatarBorder(style: 'thin', colors: ['#B']),
    ).withBorderStyle(AvatarBorderStyle.none);
    expect(d.border, isNull);
    expect(d.borderColor, '#B');
    expect(d.withBorderStyle(AvatarBorderStyle.thick).borderColor, '#B');
  });

  test('profile colours: picked, then the ring\'s, no repeats', () {
    final d = AvatarColorsDraft.from(const [
      '#A',
      '#B',
    ], const AvatarBorder(style: 'thin', colors: ['#B']));
    expect(d.profileColors, ['#A', '#B']);
    expect(d.withBorderColor('#C').profileColors, ['#A', '#B', '#C']);
  });
}
