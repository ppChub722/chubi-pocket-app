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
            title: 'PeopleStrip',
            child: PeopleStrip(
              first: true,
              title: 'People',
              description: 'Who shares this.',
              inviteLabel: 'Invite',
              onInvite: noop,
              onMemberTap: (_) {},
              members: const [
                PeopleStripMember(
                  avatar: AppAvatar(name: 'Aom Chan'),
                  name: 'Aom',
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
        ],
      ),
    );
  }
}
