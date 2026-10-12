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

  Widget _gap() => const SizedBox(height: AppSpacing.md);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget frame(Widget child) =>
        AppCard(style: AppCardStyle.bordered, child: child);
    Widget pageBg(Widget child) => ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HubSubheading(
          'Playgrounds',
          note: 'One per widget: a live instance and its real options.',
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
            final icon = v<bool>('icon') ? AppIcons.wallet : null;
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
                    'switch' => AppSwitch(value: on, onChanged: set),
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
              'label. editing flips the AppInput.inline child between a '
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
                    ? AppInput.inline(
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
              ('add (default)', AppIcons.add),
              ('link', AppIcons.link),
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
              'One detail-page section. band: a tinted band above (unless '
              'first) and hairlines between rows. grouped: heading above a '
              'rounded filled container. locked dims and blocks the rows.',
          controls: [
            PlayChoice<SectionStyle>('style', [
              for (final s in SectionStyle.values) (s.name, s),
            ]),
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
                style: v<SectionStyle>('style'),
                title: v<bool>('title') ? 'Details' : null,
                description: v<bool>('description')
                    ? 'What this is and where it sits.'
                    : null,
                trailing: v<bool>('trailing')
                    ? AppChip(
                        label: 'Share',
                        icon: AppIcons.share,
                        onTap: () {},
                      )
                    : null,
                first: v<bool>('first'),
                locked: v<bool>('locked'),
                dividers: v<bool>('dividers'),
                children: [
                  for (var i = 1; i <= v<double>('rows').round(); i++)
                    DetailRow(
                      icon: icons ? AppIcons.wallet : null,
                      label: 'Row $i',
                      trailing: Text('Value $i'),
                    ),
                ],
              ),
            );
          },
        ),
        // ---- SectionBand ----
        HubPlayground(
          title: 'SectionBand',
          note:
              'The tinted separator between sections. bleed is how far it '
              'reaches past its box on each side (the page inset).',
          controls: const [
            PlayNum('bleed', min: 0, max: 16, step: 4, initialValue: 16),
          ],
          builder: (context, v) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('above'),
              SectionBand(bleed: v<double>('bleed')),
              const Text('below'),
            ],
          ),
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
                  ? AppIconButton(
                      icon: AppIcons.sort,
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
                      icon: AppIcons.category,
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
            icon: v<bool>('caution') ? AppIcons.archive : AppIcons.delete,
            label: v<String>('label'),
            caution: v<bool>('caution'),
            padding: EdgeInsets.zero,
            onTap: v<bool>('enabled') ? () {} : null,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // ---- Band vs grouped comparison ----
        HubDemo(
          title: 'Section style — band (today) vs grouped (prototype)',
          note:
              'Grouped: the green heading and its description sit above a '
              'rounded container with a filled surface and no stroke; rows are '
              'separated by a 2 px gap (the page shows through), only the first '
              'and last rows carry the outer corners. A group with any row '
              'icon reserves the icon slot on every row so titles align. The '
              'default stays band until the owner approves; flipping '
              'kDefaultSectionStyle changes every page.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in SectionStyle.values) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(s.name, style: text.labelLarge),
                ),
                pageBg(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCard(
                        style: s,
                        first: true,
                        title: 'Details',
                        description: 'What this is and where it sits.',
                        children: [
                          DetailRow(
                            icon: AppIcons.wallet,
                            label: 'Wallet',
                            trailing: const Text('KBank'),
                          ),
                          DetailRow.pick(
                            icon: AppIcons.category,
                            label: 'Category',
                            value: null,
                            emptyText: 'Not selected',
                            onTap: () {},
                          ),
                          DetailRow(
                            icon: AppIcons.currency,
                            label: 'Currency',
                            helper: 'Fixed after create',
                            trailing: const Text('THB'),
                            locked: true,
                          ),
                          DetailRow(
                            icon: AppIcons.info,
                            label: 'Counts in reports',
                            trailing: AppSwitch(
                              value: _switch,
                              onChanged: (v) => setState(() => _switch = v),
                            ),
                          ),
                        ],
                      ),
                      SectionCard(
                        style: s,
                        title: 'No icons',
                        description:
                            'A group without icons keeps its titles flush left.',
                        children: const [
                          DetailRow(label: 'Name', trailing: Text('Food')),
                          DetailRow(label: 'Type', trailing: Text('Expense')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
        // ---- In the app ----
        HubInApp(
          note: 'The real combinations, each with the page that uses it.',
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
              child: frame(
                DetailRow(
                  label: 'Counts in reports',
                  helper: 'Counts in totals and charts',
                  trailing: AppSwitch(
                    value: _switch,
                    onChanged: (v) => setState(() => _switch = v),
                  ),
                  onTap: () => setState(() => _switch = !_switch),
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
              child: frame(
                Column(
                  children: [
                    DetailRow.pick(
                      label: 'Wallet',
                      value: 'Savings account',
                      emptyText: 'Not selected',
                      onTap: () {},
                    ),
                    const AppDivider.row(),
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
              label: 'DetailRow.pick — locked',
              page: 'Wallet detail (currency in edit mode)',
              child: frame(
                DetailRow.pick(
                  label: 'Currency',
                  value: 'THB',
                  emptyText: 'Not selected',
                  leading: const Icon(AppIcons.currency),
                  locked: true,
                ),
              ),
            ),
            HubUse(
              label: 'DetailRow.pick — horizontalInset 0',
              page: 'Debt form, quick-create event pick',
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
              label: 'DetailStacked + AppInput.inline — view / edit',
              page: 'Every detail page (the note)',
              child: frame(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppChip(
                          label: _editing ? 'Editing' : 'Viewing',
                          selected: _editing,
                          icon: AppIcons.edit,
                          onTap: () => setState(() => _editing = !_editing),
                        ),
                      ),
                    ),
                    const AppDivider.row(),
                    DetailStacked(
                      label: 'Note',
                      child: AppInput.inline(
                        editing: _editing,
                        controller: _viewNote,
                        viewHint: 'No note',
                        hint: 'Add a note',
                        maxLines: 3,
                        onEnterEdit: () => setState(() => _editing = true),
                      ),
                    ),
                    const AppDivider.row(),
                    DetailStacked(
                      label: 'Empty note',
                      child: AppInput.inline(
                        editing: _editing,
                        controller: _emptyNote,
                        viewHint: 'Long-press to add a note',
                        hint: 'Add a note',
                        onEnterEdit: () => setState(() => _editing = true),
                      ),
                    ),
                    const AppDivider.row(),
                    DetailStacked(
                      label: 'Second note',
                      child: AppInput.inline(
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
                    const AppDivider.row(),
                    DetailAddRow(label: 'Add a number', onTap: () {}),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'SectionCard — first, with title',
              page: 'All detail pages',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    first: true,
                    title: 'Sharing',
                    description: 'A short explanation of this section.',
                    trailing: AppChip(
                      label: 'Share',
                      icon: AppIcons.share,
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
              label: 'SectionBand (used directly)',
              page: 'Split event section',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Text('above'), SectionBand(), Text('below')],
              ),
            ),
            HubUse(
              label: 'SectionHeader — count + action',
              page: 'Home (recent), pending, account detail',
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
              page: 'Accounts list (wallet groups)',
              child: frame(
                SectionHeader(
                  title: 'Wallets',
                  trailing: AppIconButton(
                    icon: AppIcons.sort,
                    tooltip: 'Reorder',
                    onPressed: () {},
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'ListRow — leading, subtitle, usage count',
              page: 'Categories, tags, contacts lists',
              child: frame(
                ListRow(
                  title: 'Food',
                  subtitle: 'Used 24 times',
                  leading: IconTile(
                    icon: AppIcons.category,
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
              child: frame(
                const Column(
                  children: [
                    ListRow(
                      title: 'Level 2',
                      subtitle: 'indent: 24',
                      indent: 24,
                    ),
                    AppDivider.row(),
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
              child: frame(
                Column(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const AppDivider.row(),
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
              label: 'DangerRow — delete (red)',
              page: 'Transaction detail, debt detail, event pick',
              child: DangerRow(
                icon: AppIcons.delete,
                label: 'Delete this item',
                padding: EdgeInsets.zero,
                onTap: () {},
              ),
            ),
            HubUse(
              label: 'DangerRow — archive (caution)',
              page: 'Detail pages (the management block)',
              child: DangerRow(
                icon: AppIcons.archive,
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
                    icon: AppIcons.delete,
                    label: 'Disabled (red)',
                    padding: EdgeInsets.zero,
                    onTap: null,
                  ),
                  _gap(),
                  const DangerRow(
                    icon: AppIcons.archive,
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
      ],
    );
  }
}
