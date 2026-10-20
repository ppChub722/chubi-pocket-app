import 'package:flutter/material.dart';

import '../atoms/app_divider.dart';
import '../atoms/list_break.dart';
import '../molecules/detail_rows.dart';
import '../tokens/app_spacing.dart';

/// Rows in cards: each run of rows between [ListBreak]s (a date header) goes
/// into one [SectionCard] with 2px gaps, the break above it.
List<Widget> cardedRows(List<Widget> items) {
  final out = <Widget>[];
  var run = <Widget>[];
  void flush() {
    if (run.isEmpty) return;
    out.add(SectionCard(first: true, children: run));
    run = <Widget>[];
  }

  for (final c in items) {
    if (c is ListBreak) {
      flush();
      out.add(CardedListBreak(child: c));
    } else {
      run.add(c);
    }
  }
  flush();
  return out;
}

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
