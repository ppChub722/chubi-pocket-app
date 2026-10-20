import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/templates/detail-sections` — the detail-page section pieces: info
/// box, settings, people strip, note, end zone, tag row.
Widget buildDetailSectionsPage(BuildContext context) =>
    const _DetailSectionsDemo();

class _DetailSectionsDemo extends StatefulWidget {
  const _DetailSectionsDemo();

  @override
  State<_DetailSectionsDemo> createState() => _DetailSectionsDemoState();
}

class _DetailSectionsDemoState extends State<_DetailSectionsDemo> {
  bool _a = true;
  bool _b = false;
  String _scope = 'Whole wallet';
  bool _noteEditing = false;
  final _note = TextEditingController(text: 'Shared with the team.');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HubDemo(
            title: 'SettingMenuRow: a dropdown you can also type into',
            note:
                'The value opens the menu; custom ends it with an input box, and '
                'choosing that turns the value into a field (its ▾ reopens the '
                'menu). compact: true is the in-hero form; note adds "= ฿1,600".',
            child: _MenuRowDemo(),
          ),
          HubDemo(
            title: 'InfoBox / InfoRow',
            note:
                'A short value sits on one row; a long one stacks by itself. '
                'Pages never choose.',
            child: InfoBox(
              first: true,
              rows: [
                const InfoRow(label: 'Currency', value: 'THB'),
                const InfoRow(
                  label: 'Address',
                  value:
                      'A long value that cannot fit on the row next to its '
                      'label, so it wraps to the stacked look.',
                ),
                InfoRow(
                  label: 'Owner',
                  value: 'Aom',
                  onTap: noop,
                  showChevron: true,
                ),
                const InfoRow(
                  label: 'Category',
                  valueChip: AppChip(label: 'Food', size: ChipSize.chip),
                ),
              ],
            ),
          ),
          HubDemo(
            title: 'SettingsSection',
            child: SettingsSection(
              first: true,
              title: 'Settings',
              description: 'How this item behaves.',
              children: [
                SettingToggleRow(
                  label: 'Show in report',
                  caption: 'Counts in the monthly report.',
                  value: _a,
                  onChanged: (v) => setState(() => _a = v),
                ),
                SettingToggleRow(
                  label: 'Notify me',
                  value: _b,
                  onChanged: (v) => setState(() => _b = v),
                ),
                SettingSummaryRow(
                  label: 'Repeat',
                  summary: 'Every month',
                  onTap: noop,
                ),
              ],
            ),
          ),
          HubDemo(
            title: 'SettingDropdownRow | SettingSwitchViewRow',
            note:
                'A dropdown row shows its value as a dashed ▾ chip (never a ›: '
                'tapping opens a menu, not a page) — wrap it in an '
                'OptionMenuAnchor. The view-mode switch only SHOWS the setting; '
                'long-press enters edit, where it is live.',
            child: SettingsSection(
              first: true,
              title: 'Settings',
              description: 'Counts in totals and reports.',
              children: [
                SettingSwitchViewRow(
                  label: 'Track balance',
                  caption: 'Turn off to skip the balance.',
                  value: _a,
                  onLongPress: () => setState(() => _a = !_a),
                ),
                OptionMenuAnchor<String>(
                  selected: _scope,
                  options: [
                    for (final s in const ['None', 'Mine', 'Whole wallet'])
                      SheetOption(value: s, label: s),
                  ],
                  onSelected: (s) => setState(() => _scope = s),
                  builder: (context, toggle) => SettingDropdownRow(
                    label: 'In my report',
                    value: _scope,
                    onTap: toggle,
                  ),
                ),
                const SettingDropdownRow(
                  label: 'Busy (inert)',
                  value: 'Whole wallet',
                  onTap: null,
                ),
              ],
            ),
          ),
          HubDemo(
            title: 'PeopleStrip',
            child: PeopleStrip(
              first: true,
              title: 'People',
              description: 'Who shares this.',
              inviteLabel: 'Invite',
              onInvite: noop,
              actionLabel: 'Manage ›',
              onAction: noop,
              onMemberTap: (_) {},
              members: const [
                PeopleStripMember(
                  avatar: AppAvatar(name: 'Aom Chan'),
                  name: 'Aom',
                  lead: 'paid 200',
                  caption: 'is owed 80',
                  tone: PeopleTone.positive,
                ),
                PeopleStripMember(
                  avatar: AppAvatar(name: 'Bee'),
                  name: 'Bee',
                  caption: 'owes 120',
                  tone: PeopleTone.negative,
                ),
                PeopleStripMember(
                  avatar: AppAvatar(name: 'Chai'),
                  name: 'Chai',
                ),
              ],
            ),
          ),
          HubDemo(
            title: 'NoteSection',
            note: 'Long-press to edit; view shows the muted hint when empty.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NoteSection(
                  first: true,
                  label: 'Note',
                  editing: _noteEditing,
                  controller: _note,
                  text: _note.text,
                  hint: 'Long-press to edit',
                  onLongPress: () => setState(() => _noteEditing = true),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _noteEditing = !_noteEditing;
                    if (!_noteEditing) _note.clear();
                  }),
                  child: Text(_noteEditing ? 'Back to view (clears)' : 'Edit'),
                ),
              ],
            ),
          ),
          HubDemo(
            title: 'EndZone',
            child: EndZone(
              first: true,
              actions: [
                EndZoneAction(
                  kind: EndZoneKind.delete,
                  label: 'Delete',
                  consequence: 'Removed for good.',
                  onTap: noop,
                ),
                EndZoneAction(
                  kind: EndZoneKind.close,
                  label: 'Close',
                  consequence: 'Ends it; history is kept.',
                  onTap: noop,
                ),
                EndZoneAction(
                  kind: EndZoneKind.archive,
                  label: 'Archive',
                  consequence: 'Hidden from totals; restorable.',
                  onTap: noop,
                ),
              ],
            ),
          ),
          HubDemo(
            title: 'TagRow',
            child: TagRow(
              addLabel: 'Tag',
              onAdd: noop,
              tags: const [
                AppChip(label: '#daily', size: ChipSize.mini),
                AppChip(label: '#work', size: ChipSize.mini),
              ],
            ),
          ),
          HubDemo(
            title: 'IconChipStrip',
            note:
                'View mode, under the hero: a transaction’s tags; a budget’s '
                'categories, wallets and tags, one strip each, only the ones '
                'it has. maxLines folds the rest into "+N".',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const IconChipStrip(
                  icon: AppIcons.category,
                  maxLines: 1,
                  chips: [
                    AppChip(label: 'Food', size: ChipSize.chip),
                    AppChip(label: 'Groceries', size: ChipSize.chip),
                    AppChip(label: 'Coffee', size: ChipSize.chip),
                    AppChip(label: 'Snacks', size: ChipSize.chip),
                    AppChip(label: 'Delivery', size: ChipSize.chip),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                IconChipStrip(
                  icon: AppIcons.wallet,
                  onLongPress: noop,
                  chips: const [AppChip(label: 'KBank', size: ChipSize.chip)],
                ),
                const SizedBox(height: AppSpacing.sm),
                const IconChipStrip(
                  icon: AppIcons.tag,
                  chips: [
                    AppChip(label: 'daily', size: ChipSize.chip),
                    AppChip(label: 'work', size: ChipSize.chip),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRowDemo extends StatefulWidget {
  const _MenuRowDemo();

  @override
  State<_MenuRowDemo> createState() => _MenuRowDemoState();
}

class _MenuRowDemoState extends State<_MenuRowDemo> {
  int _pct = 80;

  @override
  Widget build(BuildContext context) {
    SettingMenuRow<int> row({bool compact = false}) => SettingMenuRow<int>(
      label: 'Warn at',
      value: _pct == 0 ? 'Off' : '$_pct%',
      note: compact && _pct > 0 ? '= ฿${2000 * _pct ~/ 100}' : null,
      compact: compact,
      selected: _pct,
      options: [
        for (final p in const [70, 80, 90, 95])
          SheetOption(value: p, label: '$p%'),
        SheetOption(value: 0, label: 'Off'),
      ],
      onSelected: (p) => setState(() => _pct = p),
      custom: SettingMenuCustom<int>(
        hint: 'Custom',
        suffix: '%',
        parse: (t) {
          final n = int.tryParse(t);
          return n == null || n < 1 ? null : n.clamp(1, 100);
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(children: [row()]),
        const SizedBox(height: AppSpacing.md),
        row(compact: true),
      ],
    );
  }
}
