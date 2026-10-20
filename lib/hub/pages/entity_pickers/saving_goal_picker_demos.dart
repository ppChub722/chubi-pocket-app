import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/saving_goals/data/saving_goals_repository.dart';
import '../../../features/saving_goals/presentation/widgets/saving_goal_picker.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// [SavingGoalPicker] as the saving entry form and the goal page's "move"
/// open it, on the real goals.
class SavingGoalPickerDemos extends StatelessWidget {
  const SavingGoalPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  static String _say(SavingBucketPick? r) => switch (r) {
    null => 'closed',
    SavingSparePicked() => 'spare',
    SavingGoalPicked(:final goal) => goal.name,
  };

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
    final repo = context.read<SavingGoalsRepository>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _demo(
          'SavingGoalPicker.one — saving entry form',
          'The spare pot and every active goal as two-column cards; no goal '
              'yet, so the spare reads as picked. "New" loads the goals in '
              'the sheet (skeleton, error, retry, pull-to-refresh); "New, '
              'goals given" gets '
              'the list the form already has, with the first goal picked.',
          [
            _new(
              'New',
              () async => _say(
                await SavingGoalPicker.one(context, spareSelected: true),
              ),
            ),
            _new('New, goals given', () async {
              final o = await repo.list();
              if (!context.mounted) return 'closed';
              final first = o.goals.firstOrNull?.id;
              return _say(
                await SavingGoalPicker.one(
                  context,
                  overview: o,
                  selectedId: first,
                  spareSelected: first == null,
                ),
              );
            }),
          ],
        ),
        _demo(
          'SavingGoalPicker.one — move, from a goal',
          'The goal page\'s "move to": its own title, the goal it moves from '
              'left out (here the first goal), the spare offered.',
          [
            _new('New', () async {
              final o = await repo.list();
              if (!context.mounted) return 'closed';
              return _say(
                await SavingGoalPicker.one(
                  context,
                  title: l.sgv2MovePick,
                  overview: o,
                  excludeIds: {?o.goals.firstOrNull?.id},
                ),
              );
            }),
          ],
        ),
        _demo(
          'SavingGoalPicker.one — move, from the spare',
          'Moving out of the spare: only the goals.',
          [
            _new(
              'New',
              () async => _say(
                await SavingGoalPicker.one(
                  context,
                  title: l.sgv2MovePick,
                  allowSpare: false,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
