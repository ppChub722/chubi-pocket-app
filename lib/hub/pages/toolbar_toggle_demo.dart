import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// The summary card's action slot + the collapsible list toolbar (owner
/// 2026-10-16): 🔍 in the card toggles the search + filter block; while it is
/// hidden with a search typed, the 🔍 wears a red dot.
class ToolbarToggleDemo extends StatefulWidget {
  const ToolbarToggleDemo({super.key});

  @override
  State<ToolbarToggleDemo> createState() => _ToolbarToggleDemoState();
}

class _ToolbarToggleDemoState extends State<ToolbarToggleDemo> {
  final _toggle = ToolbarToggleState.local();
  final _search = TextEditingController();

  @override
  void dispose() {
    _toggle.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HubDemo(
      title: 'CardActionButton | ToolbarToggleButton | ListToolbar(collapse)',
      note:
          'The card has ONE standard top-right action slot. List pages put the '
          '🔍 here; it shows / hides the toolbar under the card (hidden by '
          'default, remembered per page via ToolbarToggleState.of(key)). '
          'Type a search, hide the toolbar: the 🔍 shows a red dot.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Expanded(child: Text('Summary card')),
                ListenableBuilder(
                  listenable: _search,
                  builder: (context, _) => ToolbarToggleButton(
                    state: _toggle,
                    filtered: _search.text.isNotEmpty,
                    tooltip: 'Search',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CardActionButton(icon: AppIcons.edit, onTap: () {}),
              ],
            ),
          ),
          ListToolbar(
            collapse: _toggle,
            searchController: _search,
            searchHint: 'Search',
            chips: const [AppChip(label: 'Status: Active')],
          ),
        ],
      ),
    );
  }
}
