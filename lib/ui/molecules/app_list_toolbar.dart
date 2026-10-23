import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_input.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import 'card_action_button.dart';
import 'filter_bar.dart';
import 'sort_chip.dart';

/// A list's search box, then its filter chips with the sort at the end.
/// With [state] the whole block opens and closes from an
/// [AppListToolbarToggle] (🔍); without it the block stays open.
class AppListToolbar extends StatelessWidget {
  const AppListToolbar({
    this.state,
    this.search,
    this.filters = const [],
    this.sort,
    this.sidePadding = AppSpacing.lg,
    super.key,
  });

  static const double gap = AppSpacing.sm;

  final AppListToolbarState? state;
  final ListToolbarSearch? search;

  /// Chip-size chips (a dropdown [AppChip], a toggle chip).
  final List<Widget> filters;
  final SortChip<dynamic>? sort;

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
    final hasFilters = filters.isNotEmpty || sort != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (search != null)
            AppInput.search(
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
                trailing: sort,
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
              ),
            ),
        ],
      ),
    );
  }
}

/// The search box of an [AppListToolbar].
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

/// Open / closed of an [AppListToolbar]; [of] keeps it per page while the
/// app runs.
class AppListToolbarState extends ValueNotifier<bool> {
  AppListToolbarState._(super.open);

  AppListToolbarState.local({bool open = false}) : super(open);

  static final Map<String, AppListToolbarState> _byKey = {};

  static AppListToolbarState of(String pageKey, {bool open = false}) =>
      _byKey.putIfAbsent(pageKey, () => AppListToolbarState._(open));

  static void resetAll() => _byKey.clear();

  void toggle() => value = !value;
}

/// The 🔍 that opens an [AppListToolbar]; a dot while it's closed with a
/// filter on.
class AppListToolbarToggle extends StatelessWidget {
  const AppListToolbarToggle({
    required this.state,
    this.filtered = false,
    this.tooltip,
    super.key,
  });

  final AppListToolbarState state;
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
