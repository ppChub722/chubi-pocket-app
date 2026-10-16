import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/molecules/rows` — detail rows, sections and list rows. One
/// playground per widget (its real options), then "In the app".
Widget buildRowsPage(BuildContext context) => const _RowsPage();

class _RowsPage extends StatefulWidget {
  const _RowsPage();

  @override
  State<_RowsPage> createState() => _RowsPageState();
}

class _RowsPageState extends State<_RowsPage> {
  final _viewNote = TextEditingController(text: 'Bought on the weekend sale.');
  final _editNote = TextEditingController(text: 'Tap to change this text.');
  final _emptyNote = TextEditingController();
  bool _switch = true;
  bool _editing = false;
  final _checked = <int>{1};

  @override
  void dispose() {
    _viewNote.dispose();
    _editNote.dispose();
    _emptyNote.dispose();
    super.dispose();
  }

  Widget _gap() => const SizedBox(height: PpForgeSpacing.md);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget frame(Widget child) =>
        PpForgeCard(style: PpForgeCardStyle.bordered, child: child);
    Widget pageBg(Widget child) => ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(PpForgeSpacing.md),
        child: child,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'HintLine — where something will go',
          note:
              'Quick create, a date after today (owner 2026-10-13): the '
              'line under the date says it becomes an upcoming item and '
              'where it goes; the link part opens that page.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HintLine(
                icon: PpForgeIcons.scheduled,
                linkLabel: 'Upcoming',
                text: 'goes to drafts on 3 Nov 2026',
                onTap: () {},
              ),
              const SizedBox(height: PpForgeSpacing.sm),
              const HintLine(
                icon: PpForgeIcons.scheduled,
                text: 'A plain hint, not tappable',
              ),
            ],
          ),
        ),
        const HubDemo(
          title: 'LinkedFieldHint — fields shared with another record',
          note:
              'Edit mode, under the money fields of a transaction pulled into '
              'an event (and of the bill on the event side): amount and date '
              'are one record, an edit changes both. Muted, not a banner.',
          child: LinkedFieldHint(
            text:
                'Amount and date are shared with the event bill: an edit '
                'changes both.',
          ),
        ),
        // ---- In the app ----
        HubInApp(
          columns: 2,
          note:
              'Every real variant, side by side, each with the page that uses it.',
          uses: [
            HubUse(
              label: 'DetailRow — label + value',
              page: 'Wallet / category / contact detail',
              child: frame(
                const DetailRow(
                  label: 'Currency',
                  helper: 'Fixed after create',
                  trailing: Text('THB'),
                  locked: true,
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow — switch trailing + helper',
              page: 'Category detail, notification settings',
              wide: true,
              child: frame(
                DetailRow(
                  label: 'Counts in reports',
                  helper: 'Counts in totals and charts',
                  trailing: PpForgeSwitch(
                    value: _switch,
                    onChanged: (v) => setState(() => _switch = v),
                  ),
                  onTap: () => setState(() => _switch = !_switch),
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow — label only (no trailing)',
              page: 'Detail pages (section titles)',
              child: frame(const DetailRow(label: 'Notifications')),
            ),
            HubUse(
              label: 'DetailRow — leading icon + value',
              page: 'Wallet / budget detail',
              child: frame(
                const DetailRow(
                  icon: PpForgeIcons.wallet,
                  label: 'Wallet',
                  trailing: Text('KBank'),
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow — helper under the label',
              page: 'Category / saving goal detail',
              child: frame(
                const DetailRow(
                  label: 'Target',
                  helper: 'Counts from today',
                  trailing: Text('5,000'),
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow — switch off',
              page: 'Notification settings',
              child: frame(
                DetailRow(
                  label: 'Reminders',
                  trailing: PpForgeSwitch(value: false, onChanged: (_) {}),
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow — tappable with ›',
              page: 'Wallet detail, contact detail, accounts list',
              child: frame(
                DetailRow(
                  label: 'Members',
                  trailing: const Text('3'),
                  showChevron: true,
                  onTap: () {},
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow.pick — filled and empty',
              page: 'Budget / saving goal / scheduled detail, debt form',
              wide: true,
              child: frame(
                Column(
                  children: [
                    DetailRow.pick(
                      label: 'Wallet',
                      value: 'Savings account',
                      emptyText: 'Not selected',
                      onTap: () {},
                    ),
                    const PpForgeDivider.row(),
                    DetailRow.pick(
                      label: 'Category',
                      value: null,
                      emptyText: 'Not selected',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow.pick — an ENTITY value as its chip',
              page:
                  'Category parent, budget category, goal wallet, scheduled '
                  'account / category, event, debt counterparty',
              wide: true,
              child: frame(
                Column(
                  children: [
                    DetailRow.pick(
                      label: 'Parent',
                      valueChip: const ChipPath(
                        segments: [
                          ChipPathSegment(
                            label: 'Food & Drinks',
                            icon: PpForgeIcons.category,
                            color: Colors.orange,
                          ),
                          ChipPathSegment(
                            label: 'Food Delivery',
                            icon: PpForgeIcons.transfer,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      emptyText: 'No parent',
                      onTap: () {},
                    ),
                    const PpForgeDivider.row(),
                    DetailRow.pick(
                      label: 'Wallet',
                      valueChip: const PpForgeChip(
                        label: 'Savings',
                        icon: PpForgeIcons.wallet,
                        size: ChipSize.chip,
                      ),
                      emptyText: 'Not selected',
                      onTap: () {},
                    ),
                    const PpForgeDivider.row(),
                    DetailRow.pick(
                      label: 'Event',
                      emptyText: 'None',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow.pick — locked',
              page: 'Wallet detail (currency in edit mode)',
              child: frame(
                DetailRow.pick(
                  label: 'Currency',
                  value: 'THB',
                  emptyText: 'Not selected',
                  leading: const Icon(PpForgeIcons.currency),
                  locked: true,
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow.pick — horizontalInset 0',
              page: 'Debt form, quick-create event pick',
              wide: true,
              child: frame(
                DetailRow.pick(
                  label: 'Event',
                  value: 'Flush to the edges',
                  emptyText: 'Not selected',
                  onTap: () {},
                  horizontalInset: 0,
                ),
              ),
            ),
            HubUse(
              label: 'DetailStacked + PpForgeInput.inline — view / edit',
              page: 'Every detail page (the note)',
              wide: true,
              child: frame(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(PpForgeSpacing.md),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PpForgeChip(
                          label: _editing ? 'Editing' : 'Viewing',
                          selected: _editing,
                          icon: PpForgeIcons.edit,
                          onTap: () => setState(() => _editing = !_editing),
                        ),
                      ),
                    ),
                    const PpForgeDivider.row(),
                    DetailStacked(
                      label: 'Note',
                      child: PpForgeInput.inline(
                        editing: _editing,
                        controller: _viewNote,
                        viewHint: 'No note',
                        hint: 'Add a note',
                        maxLines: 3,
                        onEnterEdit: () => setState(() => _editing = true),
                      ),
                    ),
                    const PpForgeDivider.row(),
                    DetailStacked(
                      label: 'Empty note',
                      child: PpForgeInput.inline(
                        editing: _editing,
                        controller: _emptyNote,
                        viewHint: 'Long-press to add a note',
                        hint: 'Add a note',
                        onEnterEdit: () => setState(() => _editing = true),
                      ),
                    ),
                    const PpForgeDivider.row(),
                    DetailStacked(
                      label: 'Second note',
                      child: PpForgeInput.inline(
                        editing: _editing,
                        controller: _editNote,
                        hint: 'Add a note',
                        onEnterEdit: () => setState(() => _editing = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'DetailAddRow',
              page: 'Wallet detail (numbers), debt person page',
              child: frame(
                Column(
                  children: [
                    const DetailRow(
                      label: 'Phone',
                      trailing: Text('081 234 5678'),
                    ),
                    const PpForgeDivider.row(),
                    DetailAddRow(label: 'Add a number', onTap: () {}),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'SectionCard — first, with title',
              page: 'All detail pages',
              wide: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  SectionCard(
                    first: true,
                    title: 'Details',
                    children: [
                      DetailRow(label: 'Row one', trailing: Text('A')),
                      DetailRow(label: 'Row two', trailing: Text('B')),
                    ],
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'SectionCard — trailing action + description',
              page: 'Account / category / contact detail',
              wide: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    first: true,
                    title: 'Sharing',
                    description: 'A short explanation of this section.',
                    trailing: PpForgeChip(
                      label: 'Share',
                      icon: PpForgeIcons.share,
                      onTap: () {},
                    ),
                    children: const [
                      DetailRow(label: 'Row one', trailing: Text('A')),
                    ],
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'SectionCard — locked (edit mode)',
              page: 'Account / budget / contact detail (the management block)',
              wide: true,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    first: true,
                    title: 'Management',
                    locked: true,
                    children: [
                      DetailRow(label: 'Dimmed and inert', trailing: Text('A')),
                    ],
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'SectionHeader — count + action',
              page: 'Home (recent), project dashboard',
              wide: true,
              child: frame(
                SectionHeader(
                  title: 'Recent',
                  count: 3,
                  actionLabel: 'See all',
                  onAction: () {},
                ),
              ),
            ),
            HubUse(
              label: 'SectionHeader — icon trailing',
              page: 'No page yet (the option exists)',
              wide: true,
              child: frame(
                SectionHeader(
                  title: 'Wallets',
                  trailing: PpForgeIconButton(
                    icon: PpForgeIcons.sort,
                    tooltip: 'Reorder',
                    onPressed: () {},
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'ListRow — leading, subtitle, usage count',
              page: 'Categories, tags, contacts lists',
              wide: true,
              child: frame(
                ListRow(
                  title: 'Food',
                  subtitle: 'Used 24 times',
                  leading: IconTile(
                    icon: PpForgeIcons.category,
                    color: scheme.primary,
                    size: 40,
                    shape: IconTileShape.rounded,
                    style: IconTileStyle.solid,
                  ),
                  trailing: const Text('x24'),
                  onTap: () {},
                ),
              ),
            ),
            HubUse(
              label: 'ListRow — indent + dimmed',
              page: 'Categories (sub-levels, archived)',
              wide: true,
              child: frame(
                const Column(
                  children: [
                    ListRow(
                      title: 'Level 2',
                      subtitle: 'indent: 24',
                      indent: 24,
                    ),
                    PpForgeDivider.row(),
                    ListRow(
                      title: 'Archived',
                      subtitle: 'dimmed: true',
                      dimmed: true,
                    ),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'ListRow — selection mode',
              page: 'Categories, tags, contacts (batch edit)',
              wide: true,
              child: frame(
                Column(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const PpForgeDivider.row(),
                      ListRow(
                        title: 'Selectable row ${i + 1}',
                        subtitle: _checked.contains(i)
                            ? 'Selected'
                            : 'Not selected',
                        checked: _checked.contains(i),
                        onCheck: () => setState(() {
                          _checked.contains(i)
                              ? _checked.remove(i)
                              : _checked.add(i);
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'ListRow — no leading, no subtitle',
              page: 'Tags list, pickers',
              child: frame(ListRow(title: 'Tag name', onTap: () {})),
            ),
            HubUse(
              label: 'ListRow — body replaces title + subtitle',
              page: 'Custom list rows',
              child: frame(
                ListRow(
                  title: '',
                  body: Text('Custom body', style: text.bodyMedium),
                  trailing: const Text('x3'),
                  onTap: () {},
                ),
              ),
            ),
            HubUse(
              label: 'SectionCard — no icons',
              page: 'Detail pages',
              wide: true,
              child: pageBg(
                const SectionCard(
                  first: true,
                  title: 'Details',
                  children: [
                    DetailRow(label: 'Name', trailing: Text('Food')),
                    DetailRow(label: 'Type', trailing: Text('Expense')),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'SectionCard — no title, no dividers',
              page: 'Detail pages (first block under the hero)',
              wide: true,
              child: pageBg(
                const SectionCard(
                  first: true,
                  dividers: false,
                  children: [
                    DetailRow(label: 'Row one', trailing: Text('A')),
                    DetailRow(label: 'Row two', trailing: Text('B')),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'DangerRow — delete (red)',
              page: 'Transaction detail, debt detail, event pick',
              child: DangerRow(
                icon: PpForgeIcons.delete,
                label: 'Delete this item',
                padding: EdgeInsets.zero,
                onTap: () {},
              ),
            ),
            HubUse(
              label: 'DangerRow — archive (caution)',
              page: 'Detail pages (the management block)',
              child: DangerRow(
                icon: PpForgeIcons.archive,
                label: 'Archive this item',
                caution: true,
                padding: EdgeInsets.zero,
                onTap: () {},
              ),
            ),
            HubUse(
              label: 'DangerRow — disabled while saving',
              page: 'Detail pages',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DangerRow(
                    icon: PpForgeIcons.delete,
                    label: 'Disabled (red)',
                    padding: EdgeInsets.zero,
                    onTap: null,
                  ),
                  _gap(),
                  const DangerRow(
                    icon: PpForgeIcons.archive,
                    label: 'Disabled (caution)',
                    caution: true,
                    padding: EdgeInsets.zero,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PpForgeSpacing.lg),
        // ---- Grouped sections ----
        HubDemo(
          title: 'Grouped sections — the one section style',
          note:
              'The green heading and its description sit above a rounded '
              'container with a filled surface and no stroke; rows are '
              'separated by a 2 px gap (the page shows through), only the '
              'first and last rows carry the outer corners. A group with any '
              'row icon reserves the icon slot on every row so titles align.',
          child: pageBg(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  first: true,
                  title: 'Details',
                  description: 'What this is and where it sits.',
                  children: [
                    DetailRow(
                      icon: PpForgeIcons.wallet,
                      label: 'Wallet',
                      trailing: const Text('KBank'),
                    ),
                    DetailRow.pick(
                      icon: PpForgeIcons.category,
                      label: 'Category',
                      value: null,
                      emptyText: 'Not selected',
                      onTap: () {},
                    ),
                    DetailRow(
                      icon: PpForgeIcons.currency,
                      label: 'Currency',
                      helper: 'Fixed after create',
                      trailing: const Text('THB'),
                      locked: true,
                    ),
                    DetailRow(
                      icon: PpForgeIcons.info,
                      label: 'Counts in reports',
                      trailing: PpForgeSwitch(
                        value: _switch,
                        onChanged: (v) => setState(() => _switch = v),
                      ),
                    ),
                  ],
                ),
                const SectionCard(
                  title: 'No icons',
                  description:
                      'A group without icons keeps its titles flush left.',
                  children: [
                    DetailRow(label: 'Name', trailing: Text('Food')),
                    DetailRow(label: 'Type', trailing: Text('Expense')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const HubSubheading(
          'Customize',
          note: 'Fully custom tweaks, one per widget (collapsed).',
        ),
        // ---- DetailRow ----
        HubPlayground(
          title: 'DetailRow / DetailRow.pick',
          note:
              'kind picks the trailing: none, a value, a switch, or the pick '
              'factory (label, value, ›). locked adds a lock after the value '
              '(the row is not dimmed); showChevron adds › (pick sets it '
              'itself while onTap is set).',
          controls: [
            PlayChoice<String>('kind', [
              ('value', 'value'),
              ('none', 'none'),
              ('switch', 'switch'),
              ('pick', 'pick'),
              ('pick empty', 'pick empty'),
            ]),
            const PlayBool('icon'),
            const PlayBool('helper'),
            const PlayBool('locked'),
            const PlayBool('showChevron'),
            const PlayBool('onTap', initialValue: true),
            const PlayNum(
              'horizontalInset',
              min: 0,
              max: 24,
              step: 8,
              initialValue: 16,
            ),
          ],
          builder: (context, v) {
            final kind = v<String>('kind');
            final icon = v<bool>('icon') ? PpForgeIcons.wallet : null;
            final helper = v<bool>('helper') ? 'A short explanation' : null;
            final locked = v<bool>('locked');
            final onTap = v<bool>('onTap') ? () {} : null;
            final inset = v<double>('horizontalInset');
            if (kind.startsWith('pick')) {
              return frame(
                DetailRow.pick(
                  label: 'Wallet',
                  value: kind == 'pick' ? 'KBank savings' : null,
                  emptyText: 'Not selected',
                  icon: icon,
                  locked: locked,
                  horizontalInset: inset,
                  onTap: onTap,
                ),
              );
            }
            return frame(
              HubStateful<bool>(
                initial: true,
                builder: (context, on, set) => DetailRow(
                  label: 'Wallet',
                  icon: icon,
                  helper: helper,
                  locked: locked,
                  showChevron: v<bool>('showChevron'),
                  horizontalInset: inset,
                  onTap: onTap,
                  trailing: switch (kind) {
                    'value' => const Text('KBank savings'),
                    'switch' => PpForgeSwitch(value: on, onChanged: set),
                    _ => null,
                  },
                ),
              ),
            );
          },
        ),
        // ---- DetailStacked ----
        HubPlayground(
          title: 'DetailStacked',
          note:
              'Label on top, the child below with its text lined up under the '
              'label. editing flips the PpForgeInput.inline child between a '
              'borderless read-only view and an outlined box.',
          controls: [
            const PlayText('label', initialValue: 'Note'),
            const PlayBool('editing'),
            PlayChoice<bool>('child', [
              ('inline input', true),
              ('text', false),
            ]),
          ],
          builder: (context, v) => frame(
            HubWithController(
              initial: 'Bought on the weekend sale.',
              builder: (context, c) => DetailStacked(
                label: v<String>('label'),
                child: v<bool>('child')
                    ? PpForgeInput.inline(
                        editing: v<bool>('editing'),
                        controller: c,
                        viewHint: 'No note',
                        hint: 'Add a note',
                        maxLines: 3,
                      )
                    : const Text('Any widget can sit under the label.'),
              ),
            ),
          ),
        ),
        // ---- DetailAddRow ----
        HubPlayground(
          title: 'DetailAddRow',
          note: 'The "add one more" row at the end of a section.',
          controls: [
            const PlayText('label', initialValue: 'Add a number'),
            PlayChoice<IconData>('icon', [
              ('add (default)', PpForgeIcons.add),
              ('link', PpForgeIcons.link),
            ]),
            const PlayBool('onTap', initialValue: true),
          ],
          builder: (context, v) => frame(
            DetailAddRow(
              label: v<String>('label'),
              icon: v<IconData>('icon'),
              onTap: v<bool>('onTap') ? () {} : null,
            ),
          ),
        ),
        // ---- SectionCard ----
        HubPlayground(
          title: 'SectionCard',
          note:
              'One detail-page section: heading + description above a rounded '
              'filled container, rows 2 px apart. locked dims and blocks the rows.',
          controls: [
            const PlayBool('title', initialValue: true),
            const PlayBool('description'),
            const PlayBool('trailing'),
            const PlayBool('first', initialValue: true),
            const PlayBool('locked'),
            const PlayBool('dividers', initialValue: true),
            const PlayBool('icons'),
            const PlayNum('rows', min: 1, max: 5, step: 1, initialValue: 3),
          ],
          builder: (context, v) {
            final icons = v<bool>('icons');
            return pageBg(
              SectionCard(
                title: v<bool>('title') ? 'Details' : null,
                description: v<bool>('description')
                    ? 'What this is and where it sits.'
                    : null,
                trailing: v<bool>('trailing')
                    ? PpForgeChip(
                        label: 'Share',
                        icon: PpForgeIcons.share,
                        onTap: () {},
                      )
                    : null,
                first: v<bool>('first'),
                locked: v<bool>('locked'),
                dividers: v<bool>('dividers'),
                children: [
                  for (var i = 1; i <= v<double>('rows').round(); i++)
                    DetailRow(
                      icon: icons ? PpForgeIcons.wallet : null,
                      label: 'Row $i',
                      trailing: Text('Value $i'),
                    ),
                ],
              ),
            );
          },
        ),
        // ---- SectionHeader ----
        HubPlayground(
          title: 'SectionHeader',
          note:
              'Title, optional count, then a text action OR an icon trailing.',
          controls: [
            const PlayText('title', initialValue: 'Recent'),
            const PlayBool('count'),
            const PlayBool('action'),
            const PlayBool('trailing'),
          ],
          builder: (context, v) => frame(
            SectionHeader(
              title: v<String>('title'),
              count: v<bool>('count') ? 12 : null,
              actionLabel: v<bool>('action') ? 'See all' : null,
              onAction: v<bool>('action') ? () {} : null,
              trailing: v<bool>('trailing')
                  ? PpForgeIconButton(
                      icon: PpForgeIcons.sort,
                      tooltip: 'Reorder',
                      onPressed: () {},
                    )
                  : null,
            ),
          ),
        ),
        // ---- ListRow ----
        HubPlayground(
          title: 'ListRow',
          note:
              'A library list row. checked non-null shows a SelectCheck first '
              '(tinted when true); body replaces title + subtitle. No '
              'ListTile.',
          controls: [
            const PlayText('title', initialValue: 'Food'),
            const PlayBool('subtitle', initialValue: true),
            const PlayBool('leading', initialValue: true),
            const PlayBool('trailing', initialValue: true),
            const PlayNum('indent', min: 0, max: 48, step: 12, initialValue: 0),
            const PlayBool('dimmed'),
            PlayChoice<bool?>('checked', [
              ('null', null),
              ('false', false),
              ('true', true),
            ]),
            const PlayBool('body'),
            const PlayBool('onTap', initialValue: true),
          ],
          builder: (context, v) => frame(
            ListRow(
              title: v<String>('title'),
              subtitle: v<bool>('subtitle') ? 'One line of description' : null,
              leading: v<bool>('leading')
                  ? IconTile(
                      icon: PpForgeIcons.category,
                      color: scheme.primary,
                      size: 40,
                      shape: IconTileShape.rounded,
                      style: IconTileStyle.solid,
                    )
                  : null,
              trailing: v<bool>('trailing') ? const Text('x24') : null,
              indent: v<double>('indent'),
              dimmed: v<bool>('dimmed'),
              checked: v<bool?>('checked'),
              onCheck: () {},
              body: v<bool>('body')
                  ? Text('body replaces title', style: text.bodyMedium)
                  : null,
              onTap: v<bool>('onTap') ? () {} : null,
            ),
          ),
        ),
        // ---- DangerRow ----
        HubPlayground(
          title: 'DangerRow',
          note:
              'The destructive action at the bottom of a page. caution = '
              'amber (archive, restorable); no onTap = disabled. Default '
              'padding is 24 above; zeroed here.',
          controls: [
            PlayChoice<bool>('caution', [('red', false), ('caution', true)]),
            const PlayText('label', initialValue: 'Delete this item'),
            const PlayBool('enabled', initialValue: true),
          ],
          builder: (context, v) => DangerRow(
            icon: v<bool>('caution')
                ? PpForgeIcons.archive
                : PpForgeIcons.delete,
            label: v<String>('label'),
            caution: v<bool>('caution'),
            padding: EdgeInsets.zero,
            onTap: v<bool>('enabled') ? () {} : null,
          ),
        ),
      ],
    );
  }
}
