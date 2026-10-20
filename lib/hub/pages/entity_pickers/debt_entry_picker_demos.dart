import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/personal_debts/data/personal_debts_repository.dart';
import '../../../features/personal_debts/domain/debt_ledger.dart';
import '../../../features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../features/personal_debts/presentation/widgets/debt_entry_picker.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// [DebtEntryPicker] as the debt form's "mark as paid" opens it, on the first
/// person of the debts cache that has open entries.
class DebtEntryPickerDemos extends StatelessWidget {
  const DebtEntryPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  static const _typedKey = 'n:somchai';

  static String _say(DebtEntryPicks? r) => r == null
      ? 'closed'
      : '${r.ids.length} ticked: ${[for (final e in r.entries) _name(e)].join(', ')}';

  static String _name(DebtEntry e) {
    final d = (e.description ?? '').trim();
    return d.isEmpty ? e.amount.toStringAsFixed(2) : d;
  }

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
    final people = context.watch<DebtDirectoryCubit>().state.people;
    final p =
        people.where((p) => p.openCount > 0).firstOrNull ?? people.firstOrNull;
    final repo = context.read<PersonalDebtsRepository>();

    Future<String?> firstOpen(String key) async {
      final page = await repo.entries(
        key,
        query: const DebtEntryQuery(paid: false),
        perPage: 50,
      );
      return page.items.firstOrNull?.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p == null)
          const HubDemo(
            title: 'No debt people',
            child: AppText(
              'The debts cache is empty: sign in and add a debt first. Only '
              'the typed-name demo below works without one.',
            ),
          )
        else ...[
          _demo(
            'DebtEntryPicker.many — debt form, mark as paid',
            '${p.person.name}\'s open entries, loaded in the sheet '
                '(skeleton, error, retry and pull-to-refresh from the core). '
                'The confirm counts the ticks.',
            [
              _new(
                'New',
                () async =>
                    _say(await DebtEntryPicker.many(context, personKey: p.key)),
              ),
            ],
          ),
          _demo(
            'DebtEntryPicker.many — some already ticked',
            'Reopened after picking: the first open entry starts ticked.',
            [
              _new('New', () async {
                final id = await firstOpen(p.key);
                if (!context.mounted) return 'closed';
                return _say(
                  await DebtEntryPicker.many(
                    context,
                    personKey: p.key,
                    selected: {?id},
                  ),
                );
              }),
            ],
          ),
        ],
        _demo(
          'DebtEntryPicker.many — a name typed just now',
          'Sample person "Somchai" (not saved): nothing to load, so the sheet '
              'shows "nothing open" at once.',
          [
            _new(
              'New',
              () async => _say(
                await DebtEntryPicker.many(
                  context,
                  personKey: _typedKey,
                  entries: const [],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
