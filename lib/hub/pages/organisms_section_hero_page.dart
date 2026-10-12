import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/organisms/section-hero` — HeaderCard, the detail-page sections
/// (SectionCard / ManageSection / DetailMeta), LockedInEdit and SummaryStats.
/// (ProgressRow lives on molecules/feedback, IconTile on atoms/badge-avatar.)
Widget buildSectionHeroPage(BuildContext context) => const _SectionHeroPage();

class _SectionHeroPage extends StatefulWidget {
  const _SectionHeroPage();

  @override
  State<_SectionHeroPage> createState() => _SectionHeroPageState();
}

class _SectionHeroPageState extends State<_SectionHeroPage> {
  bool _pageEdit = false;
  bool _inReport = true;
  final _name = TextEditingController(text: 'Chiang Mai trip');
  final _description = TextEditingController(text: '3 nights, hotel');
  final _note = TextEditingController();

  static const _stats = [
    SummaryStat(label: 'Income', amount: 3000, tone: MoneyTone.income),
    SummaryStat(label: 'Expense', amount: 12400, tone: MoneyTone.expense),
    SummaryStat(label: 'Net', amount: -9400, tone: MoneyTone.signed),
  ];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  Widget _toggle(bool editing, ValueChanged<bool> onChanged) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final v in const [false, true]) ...[
        if (v) const SizedBox(width: AppSpacing.xs),
        AppChip(
          label: v ? 'Edit' : 'View',
          selected: editing == v,
          onTap: () => onChanged(v),
        ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final big = text.headlineMedium?.copyWith(fontWeight: FontWeight.w800);
    void noop() {}

    Widget chips() => const AppChip(
      label: 'Active',
      dot: true,
      tone: AppChipTone.success,
      selected: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubPlayground(
          title: 'HeaderCard',
          note:
              'The bordered card at the top of every detail page. Every option '
              'HeaderCard has: topRow (chips, or none = the row collapses), '
              'topActions, onEdit (the pencil), accent, glyph, heroStyle, '
              'onTap, trailing, footer.',
          controls: [
            PlayChoice<bool>('topRow', const [
              ('chips', true),
              ('none', false),
            ]),
            const PlayBool('topActions'),
            const PlayBool('onEdit', initialValue: true),
            PlayChoice<Color>('accent', [
              ('primary', scheme.primary),
              ('expense', palette.expense),
              ('income', palette.income),
              ('success', palette.success),
              ('error', scheme.error),
            ]),
            const PlayBool('glyph', initialValue: true),
            PlayChoice<String>('heroStyle', const [
              ('default (tinted)', 'default'),
              ('plain', 'plain'),
              ('tinted, soft border', 'soft'),
            ]),
            const PlayBool('onTap'),
            const PlayBool('trailing'),
            const PlayBool('footer', initialValue: true),
          ],
          builder: (context, v) {
            final accent = v<Color>('accent');
            final glyph = v<bool>('glyph') ? AppIcons.budget : null;
            final HeroStyle? style = switch (v<String>('heroStyle')) {
              'plain' => const HeroStyle.plain(),
              'soft' => HeroStyle.tinted(
                color: accent,
                glyph: glyph,
                strongBorder: false,
              ),
              _ => null,
            };
            return HeaderCard(
              accent: accent,
              glyph: glyph,
              heroStyle: style,
              topRow: v<bool>('topRow')
                  ? [
                      AppChip(
                        label: 'Expense',
                        icon: AppIcons.expense,
                        color: palette.expense,
                        selected: true,
                      ),
                      chips(),
                    ]
                  : const [],
              topActions: v<bool>('topActions')
                  ? [
                      AppChip(
                        icon: AppIcons.reset,
                        label: 'Adjust',
                        tone: AppChipTone.primary,
                        selected: true,
                        onTap: noop,
                      ),
                    ]
                  : const [],
              onEdit: v<bool>('onEdit') ? noop : null,
              onTap: v<bool>('onTap') ? noop : null,
              trailing: v<bool>('trailing')
                  ? const AppChip(
                      label: 'Late',
                      tone: AppChipTone.danger,
                      selected: true,
                    )
                  : null,
              leading: const IconDisplay(type: IconType.category, size: 52),
              title: const Text('Food'),
              subtitle: const Text('Food › Main meals'),
              footer: v<bool>('footer')
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MoneyText(6200, style: big),
                        const SizedBox(height: AppSpacing.sm),
                        const ProgressRow(
                          value: 0.62,
                          label: 'of ฿10,000',
                          trailing: '62%',
                        ),
                      ],
                    )
                  : null,
            );
          },
        ),
        HubInApp(
          note: 'The real HeaderCard combinations.',
          uses: [
            HubUse(
              label: 'chips + adjust action + pencil + money footer',
              page: 'Account detail, Budget detail',
              child: HeaderCard(
                accent: palette.expense,
                topRow: [
                  AppChip(
                    label: 'Expense',
                    icon: AppIcons.expense,
                    color: palette.expense,
                    selected: true,
                  ),
                  chips(),
                ],
                topActions: [
                  AppChip(
                    icon: AppIcons.reset,
                    label: 'Adjust',
                    tone: AppChipTone.primary,
                    selected: true,
                    onTap: noop,
                  ),
                ],
                onEdit: noop,
                leading: const IconDisplay(type: IconType.category, size: 52),
                title: const Text('Food'),
                subtitle: const Text('Food › Main meals'),
                footer: MoneyText(6200, style: big),
              ),
            ),
            HubUse(
              label: 'no chips — the row collapses, pencil level with title',
              page: 'Contact detail',
              child: HeaderCard(
                topRow: const [],
                onEdit: noop,
                leading: const UserAvatar(displayName: 'Lee', size: 52),
                title: const Text('Lee'),
                subtitle: const Text('Contact'),
              ),
            ),
            HubUse(
              label: 'onTap — the whole card is tappable',
              page: 'Debt person page',
              child: HeaderCard(
                onTap: noop,
                leading: const IconDisplay(type: IconType.account, size: 44),
                title: const Text('Primary (default), tappable'),
              ),
            ),
            HubUse(
              label: 'success accent + goal-reached chip + progress footer',
              page: 'Saving goal detail',
              child: HeaderCard(
                accent: palette.success,
                topRow: const [
                  AppChip(
                    label: 'Goal reached',
                    icon: AppIcons.success,
                    tone: AppChipTone.success,
                    selected: true,
                  ),
                ],
                onEdit: noop,
                leading: const IconDisplay(type: IconType.account, size: 44),
                title: const Text('Japan trip'),
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MoneyText(
                      30000,
                      style: big?.copyWith(color: palette.success),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ProgressRow(
                      value: 1,
                      color: palette.success,
                      trailing: '100%',
                    ),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'error accent + trailing status pill',
              page: 'Scheduled transaction detail (overdue)',
              child: HeaderCard(
                accent: scheme.error,
                leading: const IconDisplay(type: IconType.account, size: 44),
                title: const Text('Overdue'),
                subtitle: const Text('accent: scheme.error'),
                trailing: const AppChip(
                  label: 'Late',
                  tone: AppChipTone.danger,
                  selected: true,
                ),
              ),
            ),
            HubUse(
              label: 'detail page — sections composed',
              page: 'All detail pages',
              child: _samplePage(context, big),
            ),
          ],
        ),
        HubPlayground(
          title: 'ManageSection',
          note:
              'Last section of a detail page, edit mode only. A null label '
              'leaves the button out; a null callback disables it (saving). '
              'At least one action is required.',
          controls: [
            const PlayBool('archive', initialValue: true),
            const PlayBool('delete', initialValue: true),
            const PlayBool('first', initialValue: true),
            const PlayBool('disabled'),
          ],
          builder: (context, v) {
            final archive = v<bool>('archive');
            // At least one action: fall back to delete.
            final delete = v<bool>('delete') || !archive;
            final disabled = v<bool>('disabled');
            return ManageSection(
              first: v<bool>('first'),
              archiveLabel: archive ? 'Archive' : null,
              onArchive: disabled ? null : noop,
              deleteLabel: delete ? 'Delete' : null,
              onDelete: disabled ? null : noop,
            );
          },
        ),
        HubInApp(
          note: 'The real ManageSection combinations.',
          uses: [
            HubUse(
              label: 'archive + delete',
              page: 'Budget, Saving goal, Account, Project detail',
              child: ManageSection(
                first: true,
                archiveLabel: 'Archive',
                onArchive: noop,
                deleteLabel: 'Delete',
                onDelete: noop,
              ),
            ),
            HubUse(
              label: 'delete only (entity has no archive)',
              page: 'Contact, Category detail',
              child: ManageSection(
                first: true,
                deleteLabel: 'Delete',
                onDelete: noop,
              ),
            ),
            HubUse(
              label: 'disabled while saving — callbacks null',
              page: 'Every detail page while saving',
              child: const ManageSection(
                first: true,
                archiveLabel: 'Archive',
                deleteLabel: 'Delete',
              ),
            ),
          ],
        ),
        HubPlayground(
          title: 'DetailMeta',
          note:
              'Muted record info at the very bottom of a detail page, one line '
              'per item; empty lines render nothing. detailMetaLines builds '
              'the created / edited lines (edited only appears when updatedAt '
              'is at least a minute after createdAt).',
          controls: [
            PlayChoice<int>('lines', const [
              ('none', 0),
              ('explicit (3)', 1),
              ('created + edited', 2),
              ('never edited', 3),
            ], initial: 1),
          ],
          builder: (context, v) {
            final created = DateTime(2026, 10, 10, 14, 5);
            final lines = switch (v<int>('lines')) {
              0 => <String>[],
              1 => const [
                'Saved by Mint',
                'Saved 10 Oct 2026 14:05',
                'Last edited 11 Oct 2026 09:12',
              ],
              2 => detailMetaLines(
                context,
                createdAt: created,
                updatedAt: DateTime(2026, 10, 11, 9, 12),
              ),
              _ => detailMetaLines(
                context,
                createdAt: created,
                updatedAt: created,
              ),
            };
            return DetailMeta(lines: lines);
          },
        ),
        HubPlayground(
          title: 'LockedInEdit',
          note:
              'In edit mode everything that is not part of the edit fades to '
              '38% and stops taking input.',
          controls: [const PlayBool('locked', initialValue: true)],
          builder: (context, v) => LockedInEdit(
            locked: v<bool>('locked'),
            child: SectionCard(
              first: true,
              title: 'Recent transactions',
              children: [
                DetailRow(
                  label: 'Lunch',
                  trailing: MoneyText(120, tone: MoneyTone.expense),
                  onTap: noop,
                ),
                DetailRow(
                  label: 'Taxi',
                  trailing: MoneyText(85, tone: MoneyTone.expense),
                  onTap: noop,
                ),
              ],
            ),
          ),
        ),
        HubInApp(
          note: 'LockedInEdit wraps whatever is not being edited.',
          uses: [
            HubUse(
              label: 'locked — transactions list while the hero is in edit',
              page: 'Account, Budget, Project detail',
              child: LockedInEdit(
                locked: true,
                child: SectionCard(
                  first: true,
                  title: 'Recent transactions',
                  children: [
                    DetailRow(
                      label: 'Lunch',
                      trailing: MoneyText(120, tone: MoneyTone.expense),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        HubPlayground(
          title: 'SummaryStats',
          note:
              'Labelled amounts in a row (income · expense · net). compact = '
              'a single-line strip for the top of filtered lists. count = how '
              'many SummaryStat items.',
          controls: [
            const PlayBool('compact'),
            const PlayNum('count', min: 1, max: 3, initialValue: 3),
          ],
          builder: (context, v) => SummaryStats(
            stats: _stats.take(v<double>('count').round()).toList(),
            compact: v<bool>('compact'),
          ),
        ),
        HubInApp(
          note: 'The real SummaryStats uses.',
          uses: [
            HubUse(
              label: 'normal — in a card',
              page: 'Home, Account summary, Project totals',
              child: const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: SummaryStats(stats: _stats),
                ),
              ),
            ),
            HubUse(
              label: 'compact — one-line strip',
              page: 'Transactions list (filtered)',
              child: const SummaryStats(stats: _stats, compact: true),
            ),
          ],
        ),
      ],
    );
  }

  /// The mock detail page (view / edit).
  Widget _samplePage(BuildContext context, TextStyle? big) {
    final editing = _pageEdit;
    final enter = editing ? null : () => setState(() => _pageEdit = true);
    final palette = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _toggle(_pageEdit, (v) => setState(() => _pageEdit = v)),
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeaderCard(
                  accent: palette.primary,
                  topRow: const [
                    AppChip(
                      label: 'Active',
                      dot: true,
                      tone: AppChipTone.success,
                      selected: true,
                    ),
                  ],
                  onEdit: enter,
                  leading: EditableCircle(
                    size: 52,
                    onTap: editing ? () {} : null,
                    child: const IconDisplay(type: IconType.project, size: 52),
                  ),
                  title: AppInput.title(
                    editing: editing,
                    controller: _name,
                    hint: 'Name',
                    onEnterEdit: enter,
                  ),
                  subtitle: const Text('Travel'),
                  footer: MoneyText(
                    12450,
                    style: big?.copyWith(color: palette.primary),
                  ),
                ),
                const SizedBox(height: HeroSpacing.after),
                SectionCard(
                  first: true,
                  children: [
                    DetailRow(
                      label: 'Currency',
                      trailing: const Text('THB'),
                      onLongPress: enter,
                    ),
                    DetailRow.pick(
                      label: 'Parent',
                      value: 'Travel',
                      emptyText: 'Not selected',
                      onTap: editing ? () {} : null,
                      onLongPress: enter,
                    ),
                    DetailRow.pick(
                      label: 'Event',
                      value: null,
                      emptyText: 'Not selected',
                      onTap: editing ? () {} : null,
                      onLongPress: enter,
                    ),
                    const DetailRow(
                      label: 'Type',
                      trailing: Text('Bank'),
                      locked: true,
                    ),
                    DetailRow(
                      label: 'Count in reports',
                      helper: 'Off = left out of summaries',
                      trailing: Switch(
                        value: _inReport,
                        onChanged: (v) => setState(() => _inReport = v),
                      ),
                    ),
                  ],
                ),
                SectionCard(
                  children: [
                    DetailStacked(
                      label: 'Description',
                      child: AppInput.inline(
                        editing: editing,
                        controller: _description,
                        maxLines: 3,
                        viewHint: 'Long-press to edit',
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
                if (editing)
                  ManageSection(
                    archiveLabel: 'Archive',
                    onArchive: () {},
                    deleteLabel: 'Delete',
                    onDelete: () {},
                  ),
                const DetailMeta(
                  lines: [
                    'Saved by Mint',
                    'Saved 10 Oct 2026 14:05',
                    'Last edited 11 Oct 2026 09:12',
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
