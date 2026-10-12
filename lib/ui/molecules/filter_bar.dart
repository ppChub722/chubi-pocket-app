import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Horizontal row of filter chips (+ optional trailing sort chip) that
/// scrolls sideways when it overflows — the toolbar row under a search bar.
class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.chips,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    super.key,
  });

  final EdgeInsetsGeometry padding;

  final List<Widget> chips;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    chips[i],
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
