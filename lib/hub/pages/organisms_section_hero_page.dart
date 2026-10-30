import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/organisms/section-hero` — AppHeroCard, the detail-page sections
/// (SectionCard / ManageSection / DetailMeta), LockedInEdit and SummaryStats.
/// (ProgressRow lives on molecules/feedback, IconTile on atoms/badge-avatar.)
///
/// Real examples first (every piece, many variants side by side), the
/// playgrounds last.
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

    Widget recent({bool locked = false}) => LockedInEdit(
      locked: locked,
      child: SectionCard(
        first: true,
        title: 'Recent transactions',
        children: [
          AppDetailRow(
            label: 'Lunch',
            trailing: MoneyText(120, tone: MoneyTone.expense),
            onTap: noop,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          note:
              'AppHeroCard — the real combinations (full width: the hero is '
              'always the width of the page).',
          uses: [
            HubUse(
              wide: true,
              label: 'chips + adjust action + pencil + money footer',
              page: 'Account detail, Budget detail',
              child: AppHeroCard(
                style: HeroStyle.tinted(color: palette.expense),
                header: HeroHeader(
                  leading: [
                    AppChip(
                      label: 'Expense',
                      icon: AppIcons.expense,
                      color: palette.expense,
                      selected: true,
                    ),
                    chips(),
                  ],
                  actions: [
                    AppChip(
                      icon: AppIcons.reset,
                      label: 'Adjust',
                      tone: AppChipTone.primary,
                      selected: true,
                      onTap: noop,
                    ),
                  ],
                  onEdit: noop,
                ),
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.category, size: 52),
                    name: const Text('Food'),
                    fact: const Text('Food › Main meals'),
                  ),
                ],
                footer: [MoneyText(6200, style: big)],
              ),
            ),
            HubUse(
              wide: true,
              label: 'no chips — the row collapses, pencil level with title',
              page: 'Contact detail',
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: Theme.of(context).colorScheme.primary,
                ),
                header: HeroHeader(leading: const [], onEdit: noop),
                content: [
                  HeroIdentity(
                    icon: Avatar(AvatarData.forName('Lee'), size: 52),
                    name: const Text('Lee'),
                  ),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label: 'onTap — the whole card is tappable',
              page: 'Debt person page',
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: noop,
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.account, size: 44),
                    name: const Text('Primary (default), tappable'),
                  ),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label: 'success accent + goal-reached chip + progress footer',
              page: 'Saving goal detail',
              child: AppHeroCard(
                style: HeroStyle.tinted(color: palette.success),
                header: HeroHeader(
                  leading: const [
                    AppChip(
                      label: 'Goal reached',
                      icon: AppIcons.success,
                      tone: AppChipTone.success,
                      selected: true,
                    ),
                  ],
                  onEdit: noop,
                ),
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.account, size: 44),
                    name: const Text('Japan trip'),
                  ),
                ],
                footer: [
                  Column(
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
                ],
              ),
            ),
            HubUse(
              wide: true,
              label: 'error accent + trailing status pill',
              page: 'Scheduled transaction detail (overdue)',
              child: AppHeroCard(
                style: HeroStyle.tinted(color: scheme.error),
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.account, size: 44),
                    name: const Text('Overdue'),
                    fact: const Text('accent: scheme.error'),
                    trailing: const AppChip(
                      label: 'Late',
                      tone: AppChipTone.danger,
                      selected: true,
                    ),
                  ),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label: 'watermark glyph + income accent',
              page: 'Category detail',
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: palette.income,
                  glyph: AppIcons.category,
                ),
                header: HeroHeader(
                  leading: [
                    AppChip(
                      label: 'Income',
                      icon: AppIcons.income,
                      color: palette.income,
                      selected: true,
                    ),
                  ],
                  onEdit: noop,
                ),
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.category, size: 52),
                    name: const Text('Salary'),
                    fact: const Text('Category'),
                  ),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label:
                  'Name | description (muted, max 2 lines, ellipsis) | status chip '
                  '— the description is hidden when empty',
              page: 'Every detail page (AppHeroCard)',
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: palette.primary,
                  glyph: AppIcons.contact,
                ),
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.category, size: 44),
                    name: const Text('Lee'),
                    fact: const AppChip(
                      label: 'Linked',
                      tone: AppChipTone.success,
                      selected: true,
                      size: ChipSize.chip,
                    ),
                    description: HeroDescription(
                      controller: TextEditingController(
                        text:
                            'Flatmate in Bangkok; shares the electricity bill and '
                            'the internet, pays on the 5th of each month.',
                      ),
                      editing: false,
                      hint: 'Description',
                    ),
                  ),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label: 'HeroStyle.plain — no wash, no watermark',
              page: 'An option (AppHeroCard)',
              child: AppHeroCard(
                style: HeroStyle.plain(),
                content: [
                  HeroIdentity(
                    icon: IconDisplay(type: IconType.account, size: 44),
                    name: Text('Plain hero'),
                  ),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label: 'HeroStyle.tinted, soft border',
              page: 'Transaction detail, Account detail',
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: palette.expense,
                  glyph: AppIcons.budget,
                  strongBorder: false,
                ),
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.category, size: 44),
                    name: const Text('Soft border'),
                  ),
                ],
              ),
            ),
            for (final (label, code) in [
              (
                'Tint = the icon\x27s first background colour (a gradient uses its first stop)',
                const IconCode(bgColors: ['#7E57C2', '#26A69A']),
              ),
              (
                'A pale icon colour: the border and glyph are clamped to 3:1',
                const IconCode(bgColors: ['#FFF59D']),
              ),
              (
                'No custom icon: the entity\x27s semantic fallback (here the type colour)',
                null,
              ),
            ])
              HubUse(
                wide: true,
                label: label,
                page: 'Every hero / tinted card — IconCode.tintFor',
                child: AppHeroCard(
                  style: HeroStyle.tinted(
                    color: code.tintFor(palette, fallback: palette.income),
                    glyph: AppIcons.category,
                  ),
                  content: [
                    HeroIdentity(
                      icon: const IconDisplay(
                        type: IconType.category,
                        size: 44,
                      ),
                      name: const Text('Tinted by the icon'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        HubInApp(
          columns: 2,
          note:
              'ManageSection — just the archive / delete buttons (no heading, no box), edit mode only, at the bottom before the record info.',
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
              label: 'extra neutral action above (ManageAction)',
              page: 'Budget detail (ปิดงบ)',
              child: ManageSection(
                first: true,
                extraActions: [
                  ManageAction(
                    label: 'Close budget',
                    icon: AppIcons.success,
                    onTap: noop,
                  ),
                ],
                archiveLabel: 'Archive',
                onArchive: noop,
                deleteLabel: 'Delete',
                onDelete: noop,
              ),
            ),
            HubUse(
              label: 'delete only (no archive)',
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
            HubUse(
              label: 'not first — gap above',
              page: 'Under other sections',
              child: ManageSection(
                archiveLabel: 'Archive',
                onArchive: noop,
                deleteLabel: 'Delete',
                onDelete: noop,
              ),
            ),
          ],
        ),
        HubInApp(
          columns: 2,
          note:
              'LockedInEdit — wraps whatever is not being edited. Unlocked vs '
              'locked side by side.',
          uses: [
            HubUse(
              label: 'unlocked — view mode',
              page: 'Account, Budget, Project detail',
              child: recent(),
            ),
            HubUse(
              label: 'locked — the hero is in edit',
              page: 'Account, Budget, Project detail',
              child: recent(locked: true),
            ),
          ],
        ),
        HubInApp(
          columns: 2,
          note: 'DetailMeta — muted record info at the very bottom.',
          uses: [
            const HubUse(
              label: 'saved + edited',
              page: 'Every detail page',
              child: DetailMeta(
                lines: [
                  'Saved 10 Oct 2026 14:05',
                  'Last edited 11 Oct 2026 09:12',
                ],
              ),
            ),
            const HubUse(
              label: 'never edited — one line',
              page: 'Every detail page (fresh record)',
              child: DetailMeta(lines: ['Saved 10 Oct 2026 14:05']),
            ),
            const HubUse(
              label: 'with the author',
              page: 'Shared wallet, Project detail',
              child: DetailMeta(
                lines: [
                  'Saved by Mint',
                  'Saved 10 Oct 2026 14:05',
                  'Last edited 11 Oct 2026 09:12',
                ],
              ),
            ),
            const HubUse(
              label: 'no lines — renders nothing',
              page: 'Edit mode of a new record',
              child: DetailMeta(lines: []),
            ),
          ],
        ),
        HubInApp(
          columns: 2,
          note:
              'DetailFootnote — a page footnote under the cards, inset like a '
              'card title (DetailPageBody / DetailLayout footnote:). One fact '
              'per line.',
          uses: [
            const HubUse(
              label: 'page footnote',
              page: 'Settings › Notifications, Filters and sort',
              child: DetailFootnote(
                'Tabs, dates and search start fresh on every visit',
              ),
            ),
            const HubUse(
              label: 'record stamp (profile)',
              page: 'Settings › Profile',
              child: DetailFootnote('Saved 24 Oct 2026 12:54'),
            ),
          ],
        ),
        HubInApp(
          note: 'SummaryStats — labelled amounts in a row.',
          uses: [
            const HubUse(
              wide: true,
              label: 'normal, 3 stats — in a card',
              page: 'Home, Account summary, Project totals',
              child: AppCard(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: SummaryStats(stats: _stats),
                ),
              ),
            ),
            HubUse(
              wide: true,
              label: 'normal, 2 stats — in a card',
              page: 'Event summary, Budget period',
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SummaryStats(stats: _stats.take(2).toList()),
                ),
              ),
            ),
            const HubUse(
              wide: true,
              label: 'compact — one-line strip, 3 stats',
              page: 'Transactions list (filtered)',
              child: SummaryStats(stats: _stats, compact: true),
            ),
            HubUse(
              wide: true,
              label: 'compact — 2 stats',
              page: 'Debts list, Event transactions',
              child: SummaryStats(
                stats: _stats.take(2).toList(),
                compact: true,
              ),
            ),
          ],
        ),
        HubInApp(
          note: 'The detail page — sections composed (view ⇄ edit).',
          uses: [
            HubUse(
              wide: true,
              label: 'hero + sections + manage + meta',
              page: 'All detail pages',
              child: _samplePage(context, big),
            ),
          ],
        ),
        HubPlayground(
          title: 'AppHeroCard',
          note:
              'The bordered card at the top of every detail page. Every option '
              'AppHeroCard: a header (chips + actions, ✏️ added by the card), the content rows and an optional footer.',
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
            return AppHeroCard(
              style: style ?? HeroStyle.tinted(color: accent, glyph: glyph),
              onTap: v<bool>('onTap') ? noop : null,
              header: HeroHeader(
                leading: v<bool>('topRow')
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
                actions: v<bool>('topActions')
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
              ),
              content: [
                HeroIdentity(
                  icon: const IconDisplay(type: IconType.category, size: 52),
                  name: const Text('Food'),
                  fact: const Text('Food › Main meals'),
                  trailing: v<bool>('trailing')
                      ? const AppChip(
                          label: 'Late',
                          tone: AppChipTone.danger,
                          selected: true,
                        )
                      : null,
                ),
              ],
              footer: [
                v<bool>('footer')
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
              ],
            );
          },
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
                AppDetailRow(
                  label: 'Lunch',
                  trailing: MoneyText(120, tone: MoneyTone.expense),
                  onTap: noop,
                ),
                AppDetailRow(
                  label: 'Taxi',
                  trailing: MoneyText(85, tone: MoneyTone.expense),
                  onTap: noop,
                ),
              ],
            ),
          ),
        ),
        HubPlayground(
          title: 'SummaryStats',
          note:
              'Labelled amounts in a row (income | expense | net). compact = '
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
                AppHeroCard(
                  style: HeroStyle.tinted(color: palette.primary),
                  header: HeroHeader(
                    leading: const [
                      AppChip(
                        label: 'Active',
                        dot: true,
                        tone: AppChipTone.success,
                        selected: true,
                      ),
                    ],
                    onEdit: enter,
                  ),
                  content: [
                    HeroIdentity(
                      icon: EditableCircle(
                        size: 52,
                        onTap: editing ? () {} : null,
                        child: const IconDisplay(
                          type: IconType.project,
                          size: 52,
                        ),
                      ),
                      name: AppInput.title(
                        editing: editing,
                        controller: _name,
                        hint: 'Name',
                        onEnterEdit: enter,
                      ),
                      fact: const Text('Travel'),
                    ),
                  ],
                  footer: [
                    MoneyText(
                      12450,
                      style: big?.copyWith(color: palette.primary),
                    ),
                  ],
                ),
                SizedBox(height: HeroMetrics.of(context).after),
                SectionCard(
                  first: true,
                  children: [
                    AppDetailRow(
                      label: 'Currency',
                      trailing: const Text('THB'),
                      onLongPress: enter,
                    ),
                    AppDetailRow.pick(
                      label: 'Parent',
                      value: 'Travel',
                      emptyText: 'Not selected',
                      onTap: editing ? () {} : null,
                      onLongPress: enter,
                    ),
                    AppDetailRow.pick(
                      label: 'Event',
                      value: null,
                      emptyText: 'Not selected',
                      onTap: editing ? () {} : null,
                      onLongPress: enter,
                    ),
                    const AppDetailRow(
                      label: 'Type',
                      trailing: Text('Bank'),
                      locked: true,
                    ),
                    AppDetailRow(
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
