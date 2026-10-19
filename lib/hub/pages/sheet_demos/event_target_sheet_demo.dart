import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

/// Demo of [showEventTargetPickSheet] for the hub: buttons that open it with
/// sample data (English only).
Widget buildEventTargetSheetDemo(BuildContext context) =>
    const _EventTargetSheetDemo();

final _labels = EventTargetSheetLabels(
  title: 'Add to event',
  openTitle: 'Open events',
  newTitle: 'New event',
  newRow: 'Create a new event',
  nameHint: 'Event name',
  membersInfo: 'The event is created on save, with the split people in it.',
  remove: 'Remove from event',
  createNamed: (name) => 'Create "$name"',
);

const _events = [
  EventTargetItem(
    id: 'e1',
    name: 'Chiang Mai trip',
    subtitle: '4 people | 12 Oct – 15 Oct',
  ),
  EventTargetItem(id: 'e2', name: 'Office party', subtitle: '12 people'),
  EventTargetItem(id: 'e3', name: 'Birthday dinner'),
];

class _EventTargetSheetDemo extends StatefulWidget {
  const _EventTargetSheetDemo();

  @override
  State<_EventTargetSheetDemo> createState() => _EventTargetSheetDemoState();
}

class _EventTargetSheetDemoState extends State<_EventTargetSheetDemo> {
  String _result = 'nothing picked yet';

  Future<void> _open({
    List<EventTargetItem> items = _events,
    String? selectedId,
    bool hasCurrent = false,
    bool allowCreate = true,
  }) async {
    final r = await showEventTargetPickSheet(
      context,
      items: items,
      labels: _labels,
      suggestedName: 'Lunch with team',
      selectedId: selectedId,
      hasCurrent: hasCurrent,
      allowCreate: allowCreate,
    );
    if (!mounted) return;
    setState(
      () => _result = switch (r) {
        null => 'dismissed',
        EventPickExisting(:final id) => 'existing $id',
        EventPickNew(:final name) => 'new "$name"',
        EventPickRemove() => 'remove from event',
      },
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(
            label: 'Events + create',
            variant: AppButtonVariant.outlined,
            onPressed: _open,
          ),
          AppButton(
            label: 'In an event (remove)',
            variant: AppButtonVariant.outlined,
            onPressed: () => _open(selectedId: 'e2', hasCurrent: true),
          ),
          AppButton(
            label: 'No events',
            variant: AppButtonVariant.outlined,
            onPressed: () => _open(items: const []),
          ),
          AppButton(
            label: 'No create',
            variant: AppButtonVariant.outlined,
            onPressed: () => _open(allowCreate: false),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(_result),
    ],
  );
}
