import 'package:flutter/material.dart';

import '../atoms/app_divider.dart';
import '../atoms/list_break.dart';
import '../tokens/app_spacing.dart';

List<Widget> dividedRows(
  BuildContext context,
  List<Widget> items, {
  required double indent,
}) {
  final out = <Widget>[];
  final band = Theme.of(context).colorScheme.surfaceContainerHighest;
  for (final (i, c) in items.indexed) {
    final prevIsBreak = i > 0 && items[i - 1] is ListBreak;
    if (i > 0 && c is ListBreak && !prevIsBreak) {
      out.add(ColoredBox(color: band, child: const SizedBox(height: 8)));
    } else if (prevIsBreak && c is! ListBreak) {
      out.add(const AppDivider());
    } else if (i > 0 && c is! ListBreak && !prevIsBreak) {
      out.add(
        Padding(
          padding: EdgeInsets.only(left: indent, right: AppSpacing.lg),
          child: const AppDivider(),
        ),
      );
    }
    out.add(c);
  }
  return out;
}
