import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_input.dart';
import '../tokens/pp_forge_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import 'card_action_button.dart';
import 'filter_bar.dart';
import 'sort_chip.dart';

/// A list's search box, then its filter chips with the sort at the end.
/// With [state] the whole block opens and closes from an
/// [PpForgeListToolbarToggle] (🔍); without it the block stays open.
class PpForgeListToolbar extends StatelessWidget {
  const PpForgeListToolbar({
    this.state,
    this.search,
    this.filters = const [],
    this.sort,
    this.trailing,
    this.sidePadding = PpForgeSpacing.lg,
    super.key,
  }) : assert(sort == null || trailing == null);

  static const double gap = PpForgeSpacing.sm;

  final PpForgeListToolbarState? state;
  final ListToolbarSearch? search;

  /// Chip-size chips (a dropdown [PpForgeChip], a toggle chip).
  final List<Widget> filters;
  final SortChip<dynamic>? sort;

  /// The end of the chip row when it isn't a [sort] (a sort menu, an edit or
  /// delete button).
  final Widget? trailing;

  /// 0 inside a block that already has the page gutter.
  final double sidePadding;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    if (state == null) return _block();
    return ValueListenableBuilder<bool>(
      valueListenable: state,
      builder: (context, open, _) => AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: open ? _block() : const SizedBox(width: double.infinity),
      ),
    );
  }

  Widget _block() {
    final search = this.search;
    final end = sort ?? trailing;
    final hasFilters = filters.isNotEmpty || end != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PpForgeSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (search != null)
            PpForgeInput.search(
              key: search.key,
              controller: search.controller,
              onChanged: search.onChanged,
              hint: search.hint,
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
            ),
          if (search != null && hasFilters) const SizedBox(height: gap),
          if (hasFilters)
            ChipSizeScope(
              size: ChipSize.chip,
              child: FilterBar(
                chips: filters,
                trailing: end,
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
              ),
            ),
        ],
      ),
    );
  }
}

/// The search box of an [PpForgeListToolbar].
@immutable
class ListToolbarSearch {
  const ListToolbarSearch({
    required this.controller,
    this.onChanged,
    this.hint,
    this.key,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final Key? key;
}

/// Open / closed of an [PpForgeListToolbar]; [of] keeps it per page while the
/// app runs.
class PpForgeListToolbarState extends ValueNotifier<bool> {
  PpForgeListToolbarState._(super.open);

  PpForgeListToolbarState.local({bool open = false}) : super(open);

  static final Map<String, PpForgeListToolbarState> _byKey = {};

  static PpForgeListToolbarState of(String pageKey, {bool open = false}) =>
      _byKey.putIfAbsent(pageKey, () => PpForgeListToolbarState._(open));

  static void resetAll() => _byKey.clear();

  void toggle() => value = !value;
}

/// The 🔍 that opens an [PpForgeListToolbar]; a dot while it's closed with a
/// filter on.
class PpForgeListToolbarToggle extends StatelessWidget {
  const PpForgeListToolbarToggle({
    required this.state,
    this.filtered = false,
    this.tooltip,
    super.key,
  });

  final PpForgeListToolbarState state;
  final bool filtered;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: state,
    builder: (context, open, _) => CardActionButton(
      icon: PpForgeIcons.search,
      tooltip: tooltip,
      selected: open,
      showDot: !open && filtered,
      onTap: state.toggle,
    ),
  );
}
