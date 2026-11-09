import 'package:flutter/material.dart';

import 'package:pp_forge_ui/pp_forge_ui.dart';
import '../../app_aliases.dart';

/// One of the cards under the entry hero (owner 2026-11-03): the แบ่ง card
/// and the tx detail card (category / wallet, tags, note, รายการประจำ). Its
/// [children] stack with the kit's small gap.
class EntrySectionCard extends StatelessWidget {
  const EntrySectionCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = children;
    return AppCard(
      style: AppCardStyle.bordered,
      padding: HeroMetrics.of(context).padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// A pick row flagged as missing (a draft without its wallet / category): a
/// thin error outline around it.
class EntryFlagged extends StatelessWidget {
  const EntryFlagged({required this.flagged, required this.child, super.key});

  final bool flagged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!flagged) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpacing.xxs), child: child),
    );
  }
}
