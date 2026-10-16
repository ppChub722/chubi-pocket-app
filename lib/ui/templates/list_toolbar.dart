import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_input.dart';
import '../molecules/filter_bar.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';

/// The list pages' toolbar block (owner 2026-10-12): the search capsule and
/// the filters / sort row under it are ONE block — the gap between them is
/// [gap] (8), not two stacked paddings. Put it in `ListPageBody.header`; the
/// spacing ABOVE it (a summary, a period pill) stays the page's own.
///
/// - search: [searchController] / [onSearchChanged] / [searchHint]
///   (`PpForgeInput.search`); leave [searchController] null for no search.
/// - filters: [chips] (+ [trailing], e.g. a sort menu); empty = no row.
class ListToolbar extends StatelessWidget {
  const ListToolbar({
    this.searchController,
    this.onSearchChanged,
    this.searchHint,
    this.searchKey,
    this.chips = const [],
    this.trailing,
    super.key,
  });

  static const double gap = PpForgeSpacing.sm;

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final Key? searchKey;
  final List<Widget> chips;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchController != null;
    final hasFilters = chips.isNotEmpty || trailing != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PpForgeSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSearch)
            PpForgeInput.search(
              key: searchKey,
              controller: searchController,
              onChanged: onSearchChanged,
              hint: searchHint,
              padding: const EdgeInsets.symmetric(
                horizontal: PpForgeSpacing.lg,
              ),
            ),
          if (hasSearch && hasFilters) const SizedBox(height: gap),
          // The chip row sits one size below the search capsule (chip 28 under
          // the 40 capsule), for every list page.
          if (hasFilters)
            ChipSizeScope(
              size: ChipSize.chip,
              child: FilterBar(
                chips: chips,
                trailing: trailing,
                padding: const EdgeInsets.fromLTRB(
                  PpForgeSpacing.lg,
                  0,
                  PpForgeSpacing.lg,
                  0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
