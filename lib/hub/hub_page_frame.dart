import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/ui.dart';
import 'hub_registry.dart';
import 'hub_toolbar.dart';

/// A hub page: the header every page shares (level, generic | domain, what it
/// is, which pieces it covers, who uses it), then the demo. UI pages carry the
/// toolbar (theme · mode · language · text scale) pinned under the app bar.
class HubPageScreen extends StatefulWidget {
  const HubPageScreen({required this.page, super.key});

  final HubPage page;

  @override
  State<HubPageScreen> createState() => _HubPageScreenState();
}

class _HubPageScreenState extends State<HubPageScreen> {
  double _textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    return Scaffold(
      appBar: AppBar(title: Text(page.title)),
      body: Column(
        children: [
          if (page.level.isUi)
            HubToolbar(
              textScale: _textScale,
              onTextScale: (s) => setState(() => _textScale = s),
            ),
          Expanded(
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(_textScale)),
              child: _Body(page: page),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.page});

  final HubPage page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PpForgeSpacing.lg,
        PpForgeSpacing.md,
        PpForgeSpacing.lg,
        PpForgeSpacing.huge,
      ),
      children: [
        Wrap(
          spacing: PpForgeSpacing.xs,
          runSpacing: PpForgeSpacing.xs,
          children: [
            PpForgeChip(
              label: page.level.title,
              size: ChipSize.chip,
              tone: PpForgeChipTone.primary,
              selected: true,
            ),
            if (page.level.isUi)
              PpForgeChip(
                label: page.generic ? 'generic' : 'domain',
                size: ChipSize.chip,
                tone: page.generic
                    ? PpForgeChipTone.info
                    : PpForgeChipTone.warning,
                selected: true,
              ),
            if (!page.live)
              PpForgeChip(
                label: page.phase == 0
                    ? 'planned'
                    : 'planned · phase ${page.phase}',
                size: ChipSize.chip,
              ),
          ],
        ),
        const SizedBox(height: PpForgeSpacing.sm),
        Text(page.summary, style: text.bodyLarge),
        if (page.usedBy.isNotEmpty) ...[
          const SizedBox(height: PpForgeSpacing.xs),
          Text(
            'Used by: ${page.usedBy}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (page.covers.isNotEmpty) ...[
          const SizedBox(height: PpForgeSpacing.sm),
          Wrap(
            spacing: PpForgeSpacing.xs,
            runSpacing: PpForgeSpacing.xs,
            children: [
              for (final c in page.covers)
                PpForgeChip(label: c, size: ChipSize.mini),
            ],
          ),
        ],
        const Divider(height: PpForgeSpacing.xl),
        page.builder?.call(context) ?? HubPlanned(page: page),
      ],
    );
  }
}

/// Shown on a page that is not built yet.
class HubPlanned extends StatelessWidget {
  const HubPlanned({required this.page, super.key});

  final HubPage page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          page.phase == 0
              ? 'Not built yet.'
              : 'Not built yet — lands in phase ${page.phase}.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (page.legacyRoute != null) ...[
          const SizedBox(height: PpForgeSpacing.md),
          PpForgeButton(
            label: 'Open the current screen',
            variant: PpForgeButtonVariant.outlined,
            onPressed: () => context.push(page.legacyRoute!),
          ),
        ],
      ],
    );
  }
}
