import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/ui/organisms/collapsible-section` — a section whose heading toggles it.
Widget buildCollapsibleSectionPage(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    HubDemo(
      title: 'Open · with a hint (the แบ่งรายการ block)',
      note:
          'Rendered through SectionCard (the grouped look): heading + hint above, '
          'the rows in the filled rounded container with 2 px gaps, the '
          'chevron on the heading row. The heading toggles it; the hint sits '
          'under the title while open. Used by the split + event block of a '
          'transaction.',
      child: CollapsibleSection(
        title: 'Split',
        hint: 'Split the amount with others, or put it in an event',
        children: _rows(['Split · 2 people', 'Event · Trip']),
      ),
    ),
    HubDemo(
      title: 'Closed · with a summary',
      note:
          'Closed, the caption says what is inside. Used by pending drafts '
          '(closed by default) and the debts person history.',
      child: CollapsibleSection(
        title: 'Split',
        initiallyOpen: false,
        hint: 'Split the amount with others, or put it in an event',
        summary: '2 people · Trip',
        children: _rows(['Split · 2 people', 'Event · Trip']),
      ),
    ),
    HubDemo(
      title: 'With a mark and an action',
      child: CollapsibleSection(
        title: 'History',
        leading: const AppIcon(AppIcons.scheduled),
        summary: '5 payments',
        initiallyOpen: false,
        trailing: AppChip(label: 'Filter', size: ChipSize.chip, onTap: () {}),
        children: _rows(['12 Oct · 500', '5 Oct · 300']),
      ),
    ),
    HubDemo(
      title: 'Not collapsible',
      note: 'collapsible: false — just a titled, always-open section.',
      child: CollapsibleSection(
        title: 'Details',
        collapsible: false,
        children: _rows(['Wallet · Savings', 'Category · Food']),
      ),
    ),
  ],
);

List<Widget> _rows(List<String> lines) => [
  for (final l in lines) DetailRow(label: l),
];
