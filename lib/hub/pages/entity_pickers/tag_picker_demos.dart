import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/tags/presentation/cubit/tags_cubit.dart';
import '../../../features/tags/presentation/widgets/tag_picker.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// [TagPicker] as each page opens it, on the real tags cache.
class TagPickerDemos extends StatelessWidget {
  const TagPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  static String _names(Iterable<String> names) =>
      names.isEmpty ? 'nothing' : names.join(', ');

  static String _one(TagPick? r) => switch (r) {
    null => 'closed',
    TagPickedNone() => 'none',
    TagPicked(:final tag) => tag.name,
  };

  static String _many(TagPicks? r) => r == null
      ? 'closed'
      : _names([if (r.none) 'none', for (final t in r.tags) t.name]);

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
    final cubit = context.watch<TagsCubit>();
    final all = cubit.state.tags;
    final some = {for (final t in all.take(2)) t.id};
    final someNames = [for (final t in all.take(2)) t.name];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _demo(
          'TagPicker.many — forms, recurring, event detail',
          'Draft / debt forms, debt detail, recurring detail, event detail '
              '(their title is the default "Tags"). Chips coloured by tag, '
              'dashed when not picked; the search names a new tag ("create …" '
              'when nothing matches exactly, the name sheet when empty); the '
              'new tag is ticked and the sheet stays open.',
          [
            _new(
              'New',
              () async => _many(await TagPicker.many(context, selected: some)),
            ),
          ],
        ),
        _demo(
          'TagPicker.many — budget scope',
          'Title "Tags" of the budget; the budget keeps names, so the page '
              'maps names to ids going in and reads the names of the picks.',
          [
            _new('New', () async {
              final r = await TagPicker.many(
                context,
                selected: {
                  for (final t in all)
                    if (someNames.contains(t.name)) t.id,
                },
                title: l.bgScopeTags,
              );
              return r == null
                  ? 'closed'
                  : _names([for (final t in r.tags) t.name]);
            }),
          ],
        ),
        _demo(
          'TagPicker.many — events page filter',
          'No creating: a plain search, and the empty / no-match lines.',
          [
            _new(
              'New',
              () async => _many(
                await TagPicker.many(
                  context,
                  selected: some,
                  allowCreate: false,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'TagPicker.many — transaction filter',
          'A fixed list (the filter\'s options), no creating, its own title; '
              'it can also tick "no tag" (the filter has it as a chip of its '
              'own today).',
          [
            _new(
              'New',
              () async => _many(
                await TagPicker.many(
                  context,
                  tags: all,
                  selected: some,
                  allowCreate: false,
                  title: l.transactionsFilterTag,
                ),
              ),
            ),
            _new(
              'New + "no tag"',
              () async => _many(
                await TagPicker.many(
                  context,
                  tags: all,
                  selected: some,
                  allowCreate: false,
                  allowNone: true,
                  title: l.transactionsFilterTag,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'TagPicker.one — single (no page uses it yet)',
          'A tap answers at once; "no tag" and creating answer too.',
          [
            _new(
              'New',
              () async => _one(
                await TagPicker.one(
                  context,
                  selectedId: all.firstOrNull?.id,
                  allowNone: true,
                ),
              ),
            ),
          ],
        ),
        if (all.isEmpty)
          const HubDemo(
            title: 'No tags',
            child: AppText('The tags cache is empty: sign in first.'),
          ),
      ],
    );
  }
}
