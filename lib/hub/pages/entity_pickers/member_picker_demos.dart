import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/projects/data/projects_repository.dart';
import '../../../features/projects/domain/project.dart';
import '../../../features/projects/presentation/cubit/project_directory_cubit.dart';
import '../../../features/projects/presentation/widgets/member_picker.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// [EventMemberPicker] as the event bill form opens it (payer, split member),
/// on the first event of the events cache.
class MemberPickerDemos extends StatelessWidget {
  const MemberPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  /// Sample members (not from the server) for the big-event demo, or when the
  /// events cache is empty.
  static final _sample = [
    for (final (i, name) in const [
      'Aom',
      'Bank',
      'Chai',
      'Dao',
      'Eak',
      'Fon',
      'Golf',
      'Ice',
      'Jan',
      'Kai',
    ].indexed)
      ProjectMember(
        id: 'sample-$i',
        projectId: 'sample',
        displayName: name,
        role: i == 0 ? MemberRole.owner : MemberRole.contributor,
        status: MemberStatus.active,
        isMe: i == 0,
      ),
  ];

  static String _say(ProjectMember? m) => m?.displayName ?? 'closed';

  Widget _new(String label, Future<String> Function() run) => AppButton(
    label: label,
    variant: AppButtonVariant.outlined,
    onPressed: () async => onResult(await run()),
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
    final l = AppLocalizations.of(context)!;
    final events = context.watch<ProjectDirectoryCubit>().state;
    final event = events.formEvents.firstOrNull ?? events.projects.firstOrNull;
    final repo = context.read<ProjectsRepository>();
    final source = event == null
        ? 'sample members (the events cache is empty)'
        : '"${event.name}"\'s members';

    Future<List<ProjectMember>> members() async =>
        event == null ? _sample.take(4).toList() : repo.listMembers(event.id);

    Future<String> payer() async {
      final ms = await members();
      if (!context.mounted) return 'closed';
      final title = l.projectTxPaidBy;
      final selected = ms.firstOrNull?.id;
      return _say(
        await EventMemberPicker.one(
          context,
          title: title,
          members: ms,
          selectedId: selected,
        ),
      );
    }

    Future<String> split() async {
      final ms = await members();
      if (!context.mounted) return 'closed';
      final others = ms.skip(1).toList();
      final title = l.projectTxSplitMember;
      final selected = others.firstOrNull?.id;
      return _say(
        await EventMemberPicker.one(
          context,
          title: title,
          members: others,
          selectedId: selected,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _demo(
          'EventMemberPicker.one — payer',
          'The bill form\'s "paid by", on $source; the payer (the first '
              'member) is highlighted.',
          [_new('New', payer)],
        ),
        _demo(
          'EventMemberPicker.one — split member',
          'Who a split is for, on $source: everyone but the payer; the row\'s '
              'member is highlighted.',
          [_new('New', split)],
        ),
        _demo(
          'EventMemberPicker.one — big event',
          'Sample data: 10 made-up members, so the core adds its search '
              '(more than 8 rows).',
          [
            _new(
              'New',
              () async => _say(
                await EventMemberPicker.one(
                  context,
                  title: l.projectTxPaidBy,
                  members: _sample,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
