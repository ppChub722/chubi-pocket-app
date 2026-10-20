import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/projects/presentation/cubit/project_directory_cubit.dart';
import '../../../features/transactions/presentation/widgets/event_pick.dart';
import '../../../features/transactions/presentation/widgets/event_picker.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// [EventPicker] as each page opens it, on the real events cache.
class EventPickerDemos extends StatelessWidget {
  const EventPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  static const _suggested = 'Alice, Bob | 19 Oct 2026';

  static String _say(EventTarget? r) => switch (r) {
    null => 'closed',
    NewEventTarget(:final name) => 'new "$name"',
    ExistingEventTarget(:final project) => project.name,
    RemoveFromEvent() => 'remove from the event',
  };

  Widget _new(String label, Future<EventTarget?> Function() run) => AppButton(
    label: label,
    variant: AppButtonVariant.outlined,
    onPressed: () async => onResult(_say(await run())),
  );

  Widget _demo(String title, String note, List<Widget> buttons) => HubDemo(
    title: title,
    note: note,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: buttons,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final events = context.watch<ProjectDirectoryCubit>().state.formEvents;
    final first = events.firstOrNull?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _demo(
          'EventPicker.one — quick create',
          'Only the เปิดอยู่ tab. The first open event is the current pick. '
              'The name row at the bottom holds the suggested name (split '
              'people | date), editable, at most 100 characters; tap it and '
              '"Create …" shows. Opened on the nearest navigator, as quick '
              'create does.',
          [
            _new(
              'New',
              () => EventPicker.one(
                context,
                suggestedName: _suggested,
                selectedProjectId: first,
                showClosed: false,
                useRootNavigator: false,
              ),
            ),
          ],
        ),
        _demo(
          'EventPicker.one — draft form',
          'Open events only: no creating, a search toggle past 8 events.',
          [
            _new(
              'New',
              () => EventPicker.one(
                context,
                selectedProjectId: first,
                allowCreate: false,
              ),
            ),
          ],
        ),
        _demo(
          'EventPicker.one — transaction detail',
          'The transaction is in the first open event: that one leaves the '
              'list and "take out of the event" shows at the bottom.',
          [
            _new(
              'New',
              () => EventPicker.one(
                context,
                suggestedName: 'Lunch | 19 Oct 2026',
                currentProjectId: first,
              ),
            ),
          ],
        ),
        if (events.isEmpty)
          const HubDemo(
            title: 'No open events',
            child: AppText(
              'The events cache has no open event you can add to: sign in '
              'first, or every event shows its empty / create state.',
            ),
          ),
      ],
    );
  }
}
