import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_input.dart';
import '../molecules/card_action_button.dart';
import '../molecules/filter_bar.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';

/// The list pages' toolbar block (owner 2026-10-12): the search capsule and
/// the filters / sort row under it are ONE block — the gap between them is
/// [gap] (8), not two stacked paddings. Put it in `ListPageBody.header`; the
/// spacing ABOVE it (a summary, a period pill) stays the page's own.
///
/// - search: [searchController] / [onSearchChanged] / [searchHint]
///   (`AppInput.search`); leave [searchController] null for no search.
/// - filters: [chips] (+ [trailing], e.g. a sort menu); empty = no row.
/// - [collapse] (owner 2026-10-16): the whole block can be hidden behind a 🔍
///   [ToolbarToggleButton] in the summary card; see [ToolbarToggleState].
class ListToolbar extends StatelessWidget {
  const ListToolbar({
    this.searchController,
    this.onSearchChanged,
    this.searchHint,
    this.searchKey,
    this.chips = const [],
    this.trailing,
    this.collapse,
    this.sidePadding = AppSpacing.lg,
    super.key,
  });

  static const double gap = AppSpacing.sm;

  /// The block's own side margin (16); 0 inside a page that already pads
  /// its content (a detail page's records section).
  final double sidePadding;

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final Key? searchKey;
  final List<Widget> chips;
  final Widget? trailing;

  /// Shows / hides the block (null = always shown).
  final ToolbarToggleState? collapse;

  @override
  Widget build(BuildContext context) {
    final state = collapse;
    if (state == null) return _block(context);
    return ValueListenableBuilder<bool>(
      valueListenable: state,
      builder: (context, open, _) => AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: open ? _block(context) : const SizedBox(width: double.infinity),
      ),
    );
  }

  Widget _block(BuildContext context) {
    final hasSearch = searchController != null;
    final hasFilters = chips.isNotEmpty || trailing != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSearch)
            AppInput.search(
              key: searchKey,
              controller: searchController,
              onChanged: onSearchChanged,
              hint: searchHint,
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
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
                padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
              ),
            ),
        ],
      ),
    );
  }
}

/// Whether a list page's toolbar (search + filters) is open — remembered per
/// page for the session (owner 2026-10-16). Pages with a summary card start
/// closed; a page without one just keeps the toolbar always visible.
///
/// `ToolbarToggleState.of('budgets')` returns the same notifier every time
/// for that key, so leaving and re-entering the page keeps its state.
class ToolbarToggleState extends ValueNotifier<bool> {
  ToolbarToggleState._(super.open);

  /// A standalone notifier (tests, hub demos) — not remembered.
  ToolbarToggleState.local({bool open = false}) : super(open);

  static final Map<String, ToolbarToggleState> _byKey = {};

  /// The page's state, created closed (or [open]) the first time.
  static ToolbarToggleState of(String pageKey, {bool open = false}) =>
      _byKey.putIfAbsent(pageKey, () => ToolbarToggleState._(open));

  /// Forget every remembered state (tests).
  static void resetAll() => _byKey.clear();

  void toggle() => value = !value;
}

/// The 🔍 in a summary card's action slot: toggles [state]; while the toolbar
/// is hidden and a search / non-default filter is active ([filtered]) it
/// wears a red dot.
class ToolbarToggleButton extends StatelessWidget {
  const ToolbarToggleButton({
    required this.state,
    required this.filtered,
    this.tooltip,
    super.key,
  });

  final ToolbarToggleState state;

  /// A search text or a non-default filter is active.
  final bool filtered;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: state,
    builder: (context, open, _) => CardActionButton(
      icon: AppIcons.search,
      tooltip: tooltip,
      selected: open,
      showDot: !open && filtered,
      onTap: state.toggle,
    ),
  );
}
