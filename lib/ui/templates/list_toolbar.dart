import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/app_input.dart';
import '../molecules/card_action_button.dart';
import '../molecules/filter_bar.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';

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

  final double sidePadding;

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final Key? searchKey;
  final List<Widget> chips;
  final Widget? trailing;

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

class ToolbarToggleState extends ValueNotifier<bool> {
  ToolbarToggleState._(super.open);

  ToolbarToggleState.local({bool open = false}) : super(open);

  static final Map<String, ToolbarToggleState> _byKey = {};

  static ToolbarToggleState of(String pageKey, {bool open = false}) =>
      _byKey.putIfAbsent(pageKey, () => ToolbarToggleState._(open));

  static void resetAll() => _byKey.clear();

  void toggle() => value = !value;
}

class ToolbarToggleButton extends StatelessWidget {
  const ToolbarToggleButton({
    required this.state,
    required this.filtered,
    this.tooltip,
    super.key,
  });

  final ToolbarToggleState state;

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
