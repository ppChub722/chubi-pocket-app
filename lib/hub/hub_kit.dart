import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Building blocks for hub pages (English only): a titled specimen block, and
/// a labelled cell for a row of variants. Hub pages are built only from the
/// gate (`ui/ui.dart`) plus these.

/// One specimen: a heading, an optional note, then the demo.
class HubDemo extends StatelessWidget {
  const HubDemo({
    required this.title,
    required this.child,
    this.note,
    super.key,
  });

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: PpForgeSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleMedium),
          if (note != null) ...[
            const SizedBox(height: PpForgeSpacing.xs),
            Text(
              note!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: PpForgeSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// A demo cell: the piece with a small caption under it.
class HubCell extends StatelessWidget {
  const HubCell({required this.caption, required this.child, super.key});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: PpForgeSpacing.xs),
        Text(
          caption,
          style: text.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A wrapping row of [HubCell]s.
class HubRow extends StatelessWidget {
  const HubRow({required this.cells, super.key});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: PpForgeSpacing.lg,
    runSpacing: PpForgeSpacing.lg,
    crossAxisAlignment: WrapCrossAlignment.end,
    children: cells,
  );
}
