import 'package:flutter/material.dart';

import '../../ui.dart';

/// The รายการอัตโนมัติ box's look (spec §3 "rules live everywhere"; mock
/// AutoBox): a list header with its count and +, then one card of [rows];
/// [empty] stands in for the card once loaded with no row, an error with
/// nothing loaded shows [error] with retry. The feature's RulesBox loads
/// the rows and builds them.
class RulesBoxView extends StatelessWidget {
  const RulesBoxView({
    required this.title,
    required this.addTooltip,
    required this.onAdd,
    required this.rows,
    this.count,
    this.loaded = false,
    this.empty,
    this.error,
    this.onRetry,
    super.key,
  });

  final String title;
  final String addTooltip;
  final VoidCallback onAdd;
  final List<Widget> rows;

  /// null while loading.
  final int? count;
  final bool loaded;
  final Widget? empty;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      PpForgeListHeader(
        key: const ValueKey('rulesBoxHeader'),
        title: title,
        count: count,
        leading: const PpForgeIcon(AppIcons.recurring),
        actions: [
          ListHeaderAction.button(
            AppIcons.add,
            tooltip: addTooltip,
            onTap: onAdd,
          ),
        ],
      ),
      if (error != null && !loaded)
        ErrorView(error: error!, onRetry: onRetry)
      else if (loaded && rows.isEmpty)
        ?empty
      else if (rows.isNotEmpty)
        SectionCard(first: true, children: rows),
    ],
  );
}
