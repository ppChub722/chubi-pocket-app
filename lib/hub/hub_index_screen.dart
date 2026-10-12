import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/ui.dart';
import 'api/page_flows.dart';
import 'hub_registry.dart';

/// A section of the developer portal: one card on `/dev`, its own menu at
/// `/dev/<id>`. [levels] are the registry levels it lists. The UI section's
/// menu is one card per level (Tokens … Domain), each opening that level's
/// items at `/dev/ui/<level>`; the other sections list their pages directly.
enum HubSection {
  ui(
    'UI',
    'The app’s building blocks, smallest to whole page.',
    Icons.widgets_outlined,
    [
      HubLevel.tokens,
      HubLevel.atoms,
      HubLevel.molecules,
      HubLevel.organisms,
      HubLevel.templates,
      HubLevel.domain,
    ],
  ),
  api(
    'API',
    'What each page calls and when, the shared schemas, spec coverage.',
    Icons.api_outlined,
    [HubLevel.api],
  ),
  labs(
    'Labs',
    'Experiments against the real server: slips, chat parse.',
    Icons.science_outlined,
    [HubLevel.labs],
  ),
  debug(
    'Debug',
    'Logs, environment, the network calls and the in-memory cache.',
    Icons.bug_report_outlined,
    [HubLevel.debug],
  );

  const HubSection(this.title, this.purpose, this.icon, this.levels);

  final String title;
  final String purpose;
  final IconData icon;
  final List<HubLevel> levels;

  String get path => '/dev/$name';

  Iterable<HubPage> get pages =>
      hubPages.where((p) => levels.contains(p.level));

  /// The small count on the card.
  String get count => switch (this) {
    HubSection.api => '${pages.length} views · ${pageFlows.length} app pages',
    _ => '${pages.length} ${pages.length == 1 ? 'page' : 'pages'}',
  };

  static HubSection? byName(String name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

IconData _levelIcon(HubLevel l) => switch (l) {
  HubLevel.tokens => Icons.straighten_outlined,
  HubLevel.atoms => Icons.radio_button_unchecked,
  HubLevel.molecules => Icons.hub_outlined,
  HubLevel.organisms => Icons.view_agenda_outlined,
  HubLevel.templates => Icons.web_asset_outlined,
  HubLevel.domain => Icons.apps_outlined,
  HubLevel.api => Icons.api_outlined,
  HubLevel.labs => Icons.science_outlined,
  HubLevel.debug => Icons.bug_report_outlined,
};

IconData _pageIcon(HubPage p) => switch (p.slug) {
  'logs' => Icons.receipt_long_outlined,
  'env' => Icons.info_outline,
  'network' => Icons.swap_vert,
  'cache' => Icons.memory_outlined,
  'imports' => Icons.document_scanner_outlined,
  'pages' => Icons.account_tree_outlined,
  'schemas' => Icons.data_object,
  _ => _levelIcon(p.level),
};

/// One menu card: an icon tile, a title, a one-line purpose and a small count
/// or tag, with a chevron.
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.purpose,
    required this.onTap,
    this.tag,
    this.chips = const [],
  });

  final IconData icon;
  final String title;
  final String purpose;
  final String? tag;
  final List<Widget> chips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        style: AppCardStyle.bordered,
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            IconTile(
              icon: icon,
              color: scheme.primary,
              size: 48,
              shape: IconTileShape.rounded,
              style: IconTileStyle.solid,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    purpose,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (tag != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      tag!,
                      style: text.labelMedium?.copyWith(color: scheme.primary),
                    ),
                  ],
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: chips,
                    ),
                  ],
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

EdgeInsets get _pad => const EdgeInsets.fromLTRB(
  AppSpacing.lg,
  AppSpacing.md,
  AppSpacing.lg,
  AppSpacing.huge,
);

bool _matches(HubPage p, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return p.title.toLowerCase().contains(q) ||
      p.summary.toLowerCase().contains(q) ||
      p.slug.contains(q) ||
      p.covers.any((c) => c.toLowerCase().contains(q));
}

/// A card for one hub page (the item level of every menu).
Widget _pageCard(BuildContext context, HubPage p) => _MenuCard(
  icon: _pageIcon(p),
  title: p.title,
  purpose: p.summary,
  chips: [
    if (p.level.isUi)
      AppChip(
        label: p.generic ? 'generic' : 'domain',
        size: ChipSize.mini,
        tone: p.generic ? AppChipTone.info : AppChipTone.warning,
        selected: true,
      ),
    if (!p.live) const AppChip(label: 'planned', size: ChipSize.mini),
  ],
  onTap: () => context.push(p.path),
);

/// `/dev` — the developer portal: one card per section. A search above them
/// finds any page or piece in every section.
class HubIndexScreen extends StatefulWidget {
  const HubIndexScreen({super.key});

  @override
  State<HubIndexScreen> createState() => _HubIndexScreenState();
}

class _HubIndexScreenState extends State<HubIndexScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final searching = _query.trim().isNotEmpty;
    final found = searching
        ? hubPages.where((p) => _matches(p, _query)).toList()
        : const <HubPage>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Developer portal')),
      body: ListView(
        padding: _pad,
        children: [
          Text(
            'The single source of truth for the UI and the API. Every change '
            'lands here first, the owner reviews it, then the pages adopt it.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          AppInput.search(
            hint: 'Search every page and piece',
            padding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (searching) ...[
            for (final p in found) _pageCard(context, p),
            if (found.isEmpty)
              Text(
                'Nothing matches “$_query”.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ] else
            for (final s in HubSection.values)
              _MenuCard(
                icon: s.icon,
                title: s.title,
                purpose: s.purpose,
                tag: s.count,
                onTap: () => context.push(s.path),
              ),
        ],
      ),
    );
  }
}

/// `/dev/<section>` — one section's menu: the UI section shows one card per
/// level; the others list their pages.
class HubSectionScreen extends StatelessWidget {
  const HubSectionScreen({required this.section, super.key});

  final HubSection section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: ListView(
        padding: _pad,
        children: [
          Text(
            section.purpose,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (section == HubSection.ui)
            for (final level in section.levels)
              _MenuCard(
                icon: _levelIcon(level),
                title: level.title,
                purpose: level.blurb,
                tag: () {
                  final n = hubPages.where((p) => p.level == level).length;
                  return '$n ${n == 1 ? 'page' : 'pages'}';
                }(),
                onTap: () => context.push('/dev/ui/${level.name}'),
              )
          else
            for (final p in section.pages) _pageCard(context, p),
        ],
      ),
    );
  }
}

/// `/dev/ui/<level>` — one UI level's menu: a card per page.
class HubLevelScreen extends StatelessWidget {
  const HubLevelScreen({required this.level, super.key});

  final HubLevel level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pages = hubPages.where((p) => p.level == level).toList();
    return Scaffold(
      appBar: AppBar(title: Text(level.title)),
      body: ListView(
        padding: _pad,
        children: [
          Text(
            level.blurb,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final p in pages) _pageCard(context, p),
        ],
      ),
    );
  }
}
