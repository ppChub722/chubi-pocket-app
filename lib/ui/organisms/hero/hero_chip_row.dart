import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/chip_size.dart';

/// The chip row at the bottom of a hero card (owner 2026-10-21): every chip
/// in it is CHIP size (28), whatever size it asks for, so a status dropdown,
/// a kind pill, category / wallet / tag chips and an event chip all share one
/// height, padding, radius, font and icon size. Each keeps its own colour
/// (status green, event red, neutral with an icon). Wraps with 6 px gaps and
/// never overflows (a long label ellipsizes). The plan status chip goes LAST:
/// put it at the end of [chips].
class HeroChipRow extends StatelessWidget {
  const HeroChipRow({required this.chips, super.key});

  final List<Widget> chips;

  static const double gap = 6;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return ChipSizeScope.force(
      size: ChipSize.chip,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }
}
