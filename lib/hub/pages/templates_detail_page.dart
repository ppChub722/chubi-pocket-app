import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/templates/detail-page` — the DetailPage template: one page skeleton
/// for every entity (wallet, category, contact, event, budget, goal,
/// scheduled), view ⇄ edit, with the owner's rules visible.
Widget buildDetailPageTemplate(BuildContext context) =>
    const _DetailPageTemplate();

class _DetailPageTemplate extends StatefulWidget {
  const _DetailPageTemplate();

  @override
  State<_DetailPageTemplate> createState() => _DetailPageTemplateState();
}

class _DetailPageTemplateState extends State<_DetailPageTemplate> {
  bool _editing = false;
  bool _chips = true;
  bool _icons = true;
  bool _hasParent = false;
  bool _inReport = true;
  final _name = TextEditingController(text: 'Food');
  final _description = TextEditingController(text: 'Meals and drinks');
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  void _enter() => setState(() => _editing = true);

  static const _rules = [
    'Hero: name, then the description (muted, 2 lines; hidden when empty, '
        'edited in place in edit mode), then status chips like "Linked".',
    'Order: hero → tag row (a plain chip strip, never boxed) → ONE box with '
        'every heading-less row (basic rows + note — the note may sit alone, hairlines '
        'between) → the headed sections (heading + description outside, rows '
        'boxed) → manage (edit mode) → record info. DetailPageBody merges all '
        'heading-less groups into that one box, so a page lists them in any '
        'order.',
    'Icons per group: all rows or none (one icon indents the whole box). No '
        'lone single-row boxes — fold the row into the top box or under a '
        'heading. Description and note are stacked (label above, indented '
        'value); the input frame shows only while editing.',
    'Hero: tinted in the entity colour, a faint watermark icon, the top row '
        'holds the status chips on the left and ✏️ on the right. A top row '
        'with no chips collapses — the title moves up, ✏️ sits level with it.',
    'Every green section heading has a one-line description right under it; '
        'row labels may keep their own helper under them.',
    'Placeholder values ("Not selected", "No numbers yet", "Long-press to '
        'edit") are one faint style; tapping one enters edit mode and starts '
        'adding that thing (opens its picker / adds its row).',
    '🔒 sits right after the value, so every row label stays aligned.',
    'Pickers are AppDetailRow ›. Note is always shown, even empty. Manage '
        '(archive amber + delete red) only in edit mode, last; record info '
        '(DetailMeta) at the very bottom.',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final editing = _editing;
    final enter = editing ? null : _enter;

    final page = DetailPageBody(
      tags: const Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          AppChip(label: '#daily', size: ChipSize.mini),
          AppChip(label: '#work', size: ChipSize.mini),
        ],
      ),
      hero: AppHeroCard(
        style: HeroStyle.tinted(
          color: scheme.primary,
          glyph: AppIcons.category,
        ),
        header: HeroHeader(
          leading: _chips
              ? const [
                  AppChip(
                    label: 'Expense',
                    icon: AppIcons.expense,
                    tone: AppChipTone.danger,
                    selected: true,
                  ),
                  AppChip(
                    label: 'Hidden from report',
                    tone: AppChipTone.neutral,
                    selected: true,
                  ),
                ]
              : const [],
          onEdit: editing ? null : _enter,
        ),
        content: [
          HeroIdentity(
            icon: const IconDisplay(type: IconType.category, size: 52),
            name: HeroNameInput(
              editing: editing,
              controller: _name,
              hint: 'Name',
              onEnterEdit: enter,
            ),
            fact: const Text('Category'),
            description: HeroDescription(
              controller: _description,
              editing: editing,
              hint: 'Description',
              onEnterEdit: enter,
            ),
          ),
        ],
      ),
      sections: [
        (first) => SectionCard(
          first: first,
          title: 'Details',
          description: 'What this category is and where it sits.',
          children: [
            // Filled picker.
            AppDetailRow.pick(
              icon: _icons ? AppIcons.category : null,
              label: 'Parent',
              value: _hasParent ? 'Eating out' : null,
              emptyText: 'Not selected',
              // Empty in view mode: tap enters edit and opens the picker.
              onTap: () {
                if (!editing) _enter();
                setState(() => _hasParent = !_hasParent);
              },
              onLongPress: enter,
            ),
            AppDetailRow(
              icon: _icons ? AppIcons.currency : null,
              label: 'Currency',
              trailing: const Text('THB'),
              locked: true,
            ),
            AppDetailRow(
              icon: _icons ? AppIcons.info : null,
              label: 'Counts in reports',
              helper: 'Off = left out of summaries',
              trailing: AppSwitch(
                value: _inReport,
                onChanged: (v) => setState(() => _inReport = v),
              ),
            ),
          ],
        ),
        (first) => SectionCard(
          first: first,
          title: 'Reference numbers',
          description: 'Only used to match accounts when scanning slips.',
          children: [
            AppDetailRow(
              label: 'No numbers yet',
              onTap: () {
                if (!editing) _enter();
              },
              trailing: const DetailPlaceholder('Tap to add'),
            ),
          ],
        ),
        (first) => SectionCard(
          first: first,
          children: [
            DetailStacked(
              label: 'Note',
              child: AppInput.inline(
                editing: editing,
                controller: _note,
                maxLines: 5,
                hint: 'Add a note…',
                viewHint: 'Long-press to edit',
                onEnterEdit: enter,
              ),
            ),
          ],
        ),
      ],
      manage: editing
          ? ManageSection(
              archiveLabel: 'Archive',
              onArchive: () {},
              deleteLabel: 'Delete',
              onDelete: () {},
            )
          : null,
      metaLines: const [
        'Created 10 Oct 2026 14:05',
        'Last edited 11 Oct 2026 09:12',
      ],
    );

    Widget framed(Widget child, {double height = 460}) => Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    // Static variants: the same skeleton in the shapes the real pages use.
    Widget contactPage() => DetailPageBody(
      hero: AppHeroCard(
        style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
        header: HeroHeader(leading: const [], onEdit: () {}),
        content: [
          HeroIdentity(
            icon: const UserAvatar(displayName: 'Lee', size: 52),
            name: const Text('Lee'),
          ),
        ],
      ),
      sections: [
        (first) => SectionCard(
          first: first,
          title: 'Link',
          description: 'Connect this contact to an app user.',
          children: [
            AppDetailRow.pick(
              label: 'App user',
              value: null,
              emptyText: 'Not linked',
              onTap: () {},
            ),
          ],
        ),
        (first) => SectionCard(
          first: first,
          children: [
            DetailStacked(
              label: 'Note',
              child: AppInput.inline(
                editing: false,
                controller: _note,
                maxLines: 3,
                hint: 'Add a note…',
                viewHint: 'Long-press to edit',
              ),
            ),
          ],
        ),
      ],
      metaLines: const ['Created 10 Oct 2026 14:05'],
    );

    Widget goalPage() => DetailPageBody(
      // A tab bar under the hero (a budget's periods / items).
      tabBar: AppTabBar<int>(
        tabs: const [
          AppTab(value: 0, label: 'Periods', icon: AppIcons.history),
          AppTab(value: 1, label: 'Items', icon: AppIcons.receipt),
        ],
        selected: 0,
        onChanged: (_) {},
      ),
      hero: AppHeroCard(
        style: HeroStyle.tinted(
          color: Theme.of(context).extension<AppColors>()!.success,
        ),
        header: HeroHeader(
          leading: const [
            AppChip(
              label: 'Goal reached',
              icon: AppIcons.success,
              tone: AppChipTone.success,
              selected: true,
            ),
          ],
          onEdit: () {},
        ),
        content: [
          HeroIdentity(
            icon: const IconDisplay(type: IconType.account, size: 44),
            name: const Text('Japan trip'),
          ),
        ],
        footer: [const ProgressRow(value: 1, trailing: '100%')],
      ),
      sections: [
        (first) => SectionCard(
          first: first,
          title: 'Target',
          description: 'How much and by when.',
          children: const [
            AppDetailRow(label: 'Target', trailing: Text('฿30,000')),
            AppDetailRow(label: 'Due', trailing: Text('31 Dec 2026')),
          ],
        ),
      ],
      manage: ManageSection(
        archiveLabel: 'Archive',
        onArchive: () {},
        deleteLabel: 'Delete',
        onDelete: () {},
      ),
      metaLines: const ['Created 10 Oct 2026 14:05'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          note:
              'The real detail pages all use this skeleton. The first one is '
              'live; the others are the same template in other shapes.',
          uses: [
            HubUse(
              wide: true,
              label:
                  'DetailPageBody — view ⇄ edit (toggle the chips to see the '
                  'collapsed top row)',
              page:
                  'Account, Category, Contact, Budget, Saving goal, '
                  'Scheduled, Project, Debt detail',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppChip(
                        label: 'View',
                        selected: !editing,
                        onTap: () => setState(() => _editing = false),
                      ),
                      AppChip(label: 'Edit', selected: editing, onTap: _enter),
                      AppChip(
                        label: 'Status chips',
                        selected: _chips,
                        onTap: () => setState(() => _chips = !_chips),
                      ),
                      AppChip(
                        label: 'Row icons',
                        selected: _icons,
                        onTap: () => setState(() => _icons = !_icons),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  framed(page, height: 760),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label:
                  'loading — the skeleton mirrors the page: hero, tag strip, the '
                  'one top box, headed sections (same paddings and line heights)',
              page: 'Every detail page on first load (DetailPageSkeleton)',
              child: framed(
                const DetailPageSkeleton(
                  tags: true,
                  rows: 3,
                  sections: [2, 3],
                  topInset: 16,
                ),
                height: 640,
              ),
            ),
            HubUse(
              wide: true,
              label: 'no status chips, a picker + a note, record info only',
              page: 'Contact detail',
              child: framed(contactPage(), height: 520),
            ),
            HubUse(
              wide: true,
              label: 'success hero with progress, manage section, one section',
              page: 'Saving goal detail',
              child: framed(goalPage(), height: 560),
            ),
          ],
        ),
        HubDemo(
          title: 'The rules',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, r) in _rules.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('${i + 1}. $r', style: text.bodySmall),
                ),
            ],
          ),
        ),
        HubPlayground(
          title: 'DetailPageBody',
          note:
              'The template: hero → sections → manage → meta in one ListView. '
              'Real options: sections (count; each told if it is first), '
              'manage (null outside edit), metaLines (empty = none), '
              'topInset (a transparent top bar floats over it), bottomInset '
              '(clearance for a floating bar).',
          controls: [
            const PlayNum('sections', min: 0, max: 3, initialValue: 2),
            const PlayBool('manage'),
            const PlayBool('metaLines', initialValue: true),
            const PlayNum(
              'topInset',
              min: 0,
              max: 64,
              step: 16,
              initialValue: 0,
            ),
            const PlayNum(
              'bottomInset',
              min: 0,
              max: 96,
              step: 16,
              initialValue: 32,
            ),
          ],
          builder: (context, v) => framed(
            DetailPageBody(
              topInset: v<double>('topInset'),
              bottomInset: v<double>('bottomInset'),
              hero: AppHeroCard(
                style: HeroStyle.tinted(
                  color: Theme.of(context).colorScheme.primary,
                ),
                content: [
                  HeroIdentity(
                    icon: IconDisplay(type: IconType.category, size: 52),
                    name: Text('Food'),
                    fact: Text('Category'),
                  ),
                ],
              ),
              sections: [
                for (var i = 0; i < v<double>('sections').round(); i++)
                  (first) => SectionCard(
                    first: first,
                    title: 'Section ${i + 1}',
                    description: 'One line about this section.',
                    children: const [
                      AppDetailRow(label: 'Currency', trailing: Text('THB')),
                    ],
                  ),
              ],
              manage: v<bool>('manage')
                  ? ManageSection(
                      archiveLabel: 'Archive',
                      onArchive: () {},
                      deleteLabel: 'Delete',
                      onDelete: () {},
                    )
                  : null,
              metaLines: v<bool>('metaLines')
                  ? const ['Created 10 Oct 2026 14:05']
                  : const [],
            ),
          ),
        ),
      ],
    );
  }
}
