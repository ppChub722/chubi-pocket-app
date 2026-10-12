import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/ui/atoms/chip` — the one chip: a playground with every option live,
/// then the three sizes × every trailing, in both selected states.
Widget buildChipPage(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const HubSubheading(
      'In the app',
      note:
          'The three sizes (mini 20 · chip 28 · control 32) × every trailing, '
          'unselected and selected.',
    ),
    const _SizeMatrix(),

    HubPlayground(
      title: 'AppChip',
      note: 'Every option AppChip has.',
      controls: [
        PlayText('label', initialValue: 'Food'),
        PlayChoice<AppChipTone?>('tone', [
          ('default', null),
          for (final t in AppChipTone.values) (t.name, t),
        ]),
        PlayChoice<ChipSize>('size', [
          for (final s in ChipSize.values) ('${s.name} ${s.height.round()}', s),
        ], initial: ChipSize.control),
        PlayChoice<AppChipTrailing>('trailing', [
          for (final t in AppChipTrailing.values) (t.name, t),
        ]),
        PlayNum('count', min: 0, max: 120, step: 1, initialValue: 3),
        PlayBool('icon', initialValue: true),
        PlayBool('avatar'),
        PlayBool('dot'),
        PlayBool('selected', initialValue: true),
        PlayBool('dashed'),
        PlayBool('tappable', initialValue: true),
        PlayBool('enabled', initialValue: true),
        PlayNum('maxWidth', min: 0, max: 240, step: 20, initialValue: 0),
      ],
      builder: (context, v) {
        final avatar = v<bool>('avatar');
        final maxWidth = v<double>('maxWidth');
        return Align(
          alignment: Alignment.centerLeft,
          child: AppChip(
            label: v<String>('label'),
            icon: v<bool>('icon') && !avatar ? AppIcons.category : null,
            leading: avatar ? const UserAvatar(displayName: 'Lee') : null,
            dot: v<bool>('dot'),
            tone: v<AppChipTone?>('tone'),
            selected: v<bool>('selected'),
            dashed: v<bool>('dashed'),
            onTap: v<bool>('tappable') ? () {} : null,
            trailing: v<AppChipTrailing>('trailing'),
            onRemove: () {},
            count: v<double>('count').round(),
            size: v<ChipSize>('size'),
            enabled: v<bool>('enabled'),
            maxWidth: maxWidth == 0 ? null : maxWidth,
          ),
        );
      },
    ),
  ],
);

// ─── Size matrix ──────────────────────────────────────────────────────

/// The 3 sizes × every trailing, with the leading variants (icon / avatar /
/// dot) and count 0 / 3 / 120.
class _SizeMatrix extends StatelessWidget {
  const _SizeMatrix();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget row(ChipSize s, String name, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '$name ${s.height.round()}',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          ...chips,
        ],
      ),
    );
    final sizes = [
      (ChipSize.mini, 'mini'),
      (ChipSize.chip, 'chip'),
      (ChipSize.control, 'control'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final selected in [false, true]) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              selected ? 'Selected' : 'Not selected',
              style: textTheme.labelLarge,
            ),
          ),
          for (final (s, name) in sizes)
            row(s, name, [
              AppChip(label: 'Food', size: s, selected: selected),
              AppChip(
                label: 'Icon',
                icon: AppIcons.category,
                size: s,
                selected: selected,
              ),
              AppChip(
                label: 'Avatar',
                leading: const UserAvatar(displayName: 'Lee'),
                size: s,
                selected: selected,
              ),
              AppChip(label: 'Dot', dot: true, size: s, selected: selected),
              AppChip(
                label: 'Filter',
                size: s,
                selected: selected,
                trailing: AppChipTrailing.dropdown,
                onTap: () {},
              ),
              AppChip(
                label: 'Removable',
                size: s,
                selected: selected,
                trailing: AppChipTrailing.remove,
                onRemove: () {},
              ),
              AppChip(
                label: 'Locked',
                size: s,
                selected: selected,
                trailing: AppChipTrailing.lock,
              ),
              AppChip(
                label: 'Count',
                size: s,
                selected: selected,
                trailing: AppChipTrailing.count,
                count: 3,
              ),
              AppChip(
                label: 'Count',
                size: s,
                selected: selected,
                trailing: AppChipTrailing.count,
                count: 120,
              ),
              AppChip(
                label: 'Count 0 (hidden)',
                size: s,
                selected: selected,
                trailing: AppChipTrailing.count,
                count: 0,
              ),
            ]),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
