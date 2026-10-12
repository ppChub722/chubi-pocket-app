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
  SectionStyle _style = SectionStyle.band;
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
    'Hero: tinted in the entity colour, a faint watermark icon, the top row '
        'holds the status chips on the left and ✏️ on the right. A top row '
        'with no chips collapses — the title moves up, ✏️ sits level with it.',
    'Every green section heading has a one-line description right under it; '
        'row labels may keep their own helper under them.',
    'Placeholder values ("Not selected", "No numbers yet", "Long-press to '
        'edit") are one faint style; tapping one enters edit mode and starts '
        'adding that thing (opens its picker / adds its row).',
    '🔒 sits right after the value, so every row label stays aligned.',
    'Pickers are DetailRow ›. Note is always shown, even empty. Manage '
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
      hero: HeaderCard(
        accent: scheme.primary,
        glyph: AppIcons.category,
        topRow: _chips
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
        leading: const IconDisplay(type: IconType.category, size: 52),
        title: AppInput.title(
          editing: editing,
          controller: _name,
          hint: 'Name',
          onEnterEdit: enter,
        ),
        subtitle: const Text('Category'),
      ),
      sections: [
        (first) => SectionCard(
          first: first,
          title: 'Details',
          description: 'What this category is and where it sits.',
          children: [
            // Filled picker.
            DetailRow.pick(
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
            DetailRow(
              icon: _icons ? AppIcons.currency : null,
              label: 'Currency',
              trailing: const Text('THB'),
              locked: true,
            ),
            DetailRow(
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
            DetailRow(
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
              label: 'Description',
              child: AppInput.inline(
                editing: editing,
                controller: _description,
                maxLines: 3,
                onEnterEdit: enter,
              ),
            ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          builder: (context, v) => Container(
            height: 460,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            clipBehavior: Clip.antiAlias,
            child: DetailPageBody(
              topInset: v<double>('topInset'),
              bottomInset: v<double>('bottomInset'),
              hero: const HeaderCard(
                leading: IconDisplay(type: IconType.category, size: 52),
                title: Text('Food'),
                subtitle: Text('Category'),
              ),
              sections: [
                for (var i = 0; i < v<double>('sections').round(); i++)
                  (first) => SectionCard(
                    first: first,
                    title: 'Section ${i + 1}',
                    description: 'One line about this section.',
                    children: const [
                      DetailRow(label: 'Currency', trailing: Text('THB')),
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
        HubInApp(
          note: 'The real detail pages all use this skeleton.',
          uses: [
            HubUse(
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
                        label: 'Band',
                        selected: _style == SectionStyle.band,
                        onTap: () => setState(() => _style = SectionStyle.band),
                      ),
                      AppChip(
                        label: 'Grouped',
                        selected: _style == SectionStyle.grouped,
                        onTap: () =>
                            setState(() => _style = SectionStyle.grouped),
                      ),
                      AppChip(
                        label: 'Row icons',
                        selected: _icons,
                        onTap: () => setState(() => _icons = !_icons),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    height: 760,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SectionStyleScope(style: _style, child: page),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
