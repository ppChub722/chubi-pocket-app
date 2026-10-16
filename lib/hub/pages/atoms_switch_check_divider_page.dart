import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/atoms/switch-check-divider` — switch, select check, divider, add
/// tile, skeletons, spinner, icon. Playgrounds on top, then "In the app".
Widget buildSwitchCheckDividerPage(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  Widget left(Widget child) =>
      Align(alignment: Alignment.centerLeft, child: child);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubInApp(
        columns: 2,
        note:
            'Every real combination side by side, each with the page that '
            'uses it.',
        uses: [
          HubUse(
            label:
                'PpForgeSwitch — trailing of a DetailRow, the row toggles it',
            page: 'Detail / edit pages (include in reports, active, …)',
            wide: true,
            child: HubStateful<bool>(
              initial: true,
              builder: (context, on, set) => Column(
                children: [
                  DetailRow(
                    label: 'Include in my reports',
                    helper: 'Counts in totals and charts',
                    trailing: PpForgeSwitch(value: on, onChanged: set),
                    onTap: () => set(!on),
                  ),
                  const PpForgeDivider.row(),
                  const DetailRow(
                    label: 'Disabled',
                    trailing: PpForgeSwitch(value: false, onChanged: null),
                  ),
                ],
              ),
            ),
          ),
          HubUse(
            label: 'PpForgeSwitch — on / off',
            page: 'Notification settings',
            child: HubStateful<bool>(
              initial: true,
              builder: (context, on, set) => Wrap(
                spacing: PpForgeSpacing.lg,
                children: [
                  PpForgeSwitch(value: on, onChanged: set),
                  PpForgeSwitch(value: !on, onChanged: (x) => set(!x)),
                ],
              ),
            ),
          ),
          const HubUse(
            label: 'PpForgeSwitch — disabled (on / off)',
            page: 'Locked settings',
            child: Wrap(
              spacing: PpForgeSpacing.lg,
              children: [
                PpForgeSwitch(value: true, onChanged: null),
                PpForgeSwitch(value: false, onChanged: null),
              ],
            ),
          ),
          HubUse(
            label: 'SelectCheck — on / off / partial',
            page: 'Pending, Tags, project transactions (select mode)',
            child: HubStateful<bool?>(
              initial: true,
              builder: (context, on, set) => Wrap(
                spacing: PpForgeSpacing.lg,
                runSpacing: PpForgeSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SelectCheck(value: on, onTap: () => set(!(on ?? false))),
                  SelectCheck(value: false, onTap: () {}),
                  SelectCheck(value: null, onTap: () {}),
                ],
              ),
            ),
          ),
          HubUse(
            label: 'SelectAllCount — none / some / all / empty',
            page: 'Select-mode bars',
            child: Wrap(
              spacing: PpForgeSpacing.lg,
              runSpacing: PpForgeSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SelectAllCount(selected: 0, total: 5, onTap: () {}),
                SelectAllCount(selected: 2, total: 5, onTap: () {}),
                SelectAllCount(selected: 5, total: 5, onTap: () {}),
                SelectAllCount(selected: 0, total: 0, onTap: () {}),
              ],
            ),
          ),
          const HubUse(
            label: 'PpForgeDivider.row — between rows of a section',
            page: 'Detail sections, settings',
            child: Column(
              children: [Text('row'), PpForgeDivider.row(), Text('row')],
            ),
          ),
          const HubUse(
            label: 'PpForgeDivider — full width / taller gap',
            page: 'Sheets, lists',
            child: Column(
              children: [
                Text('above'),
                PpForgeDivider(),
                Text('between'),
                PpForgeDivider(height: 24),
                Text('below'),
              ],
            ),
          ),
          HubUse(
            label: 'AddTile — card (an empty list\'s CTA)',
            page: 'Accounts, Budgets, Categories, Contacts',
            child: AddTile(label: 'Add new', onTap: () {}),
          ),
          HubUse(
            label: 'AddTile — row (below a list)',
            page: 'Home, Pending, Wallet members',
            child: AddTile(
              label: 'Add row',
              variant: AddTileVariant.row,
              onTap: () {},
            ),
          ),
          HubUse(
            label: 'AddTile — circle',
            page: 'Icon / avatar pickers',
            child: left(
              AddTile(
                label: 'circle',
                variant: AddTileVariant.circle,
                onTap: () {},
              ),
            ),
          ),
          const HubUse(
            label: 'AddTile — disabled (saving)',
            page: 'Tags (while saving)',
            child: AddTile(label: 'Add new', onTap: null),
          ),
          const HubUse(
            label: 'PpForgeSpinner — small / medium / large',
            page: 'Login button, Debt person page, Splash',
            child: Wrap(
              spacing: PpForgeSpacing.lg,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PpForgeSpinner(size: PpForgeSpinnerSize.small),
                PpForgeSpinner(),
                PpForgeSpinner(size: PpForgeSpinnerSize.large),
              ],
            ),
          ),
          const HubUse(
            label: 'PpForgeSpinner — determinate',
            page: 'Uploads, imports',
            child: Wrap(
              spacing: PpForgeSpacing.lg,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PpForgeSpinner(value: 0.25),
                PpForgeSpinner(value: 0.75),
              ],
            ),
          ),
          const HubUse(
            label: 'Skeletons — first load of a list / card',
            page: 'Accounts, Account detail, lists',
            wide: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonListTile(),
                SkeletonBox(height: 64, borderRadius: PpForgeRadius.lg),
                SizedBox(height: PpForgeSpacing.sm),
                Row(
                  children: [
                    SkeletonCircle(size: 32),
                    SizedBox(width: PpForgeSpacing.md),
                    Expanded(child: SkeletonLine(width: 160)),
                  ],
                ),
                SizedBox(height: PpForgeSpacing.sm),
                SkeletonText(style: _bodyLarge, width: 200),
              ],
            ),
          ),
          HubUse(
            label: 'PpForgeIcon — inherited colour / primary',
            page: 'Rows, chips, empty states (72 usages)',
            child: Wrap(
              spacing: PpForgeSpacing.md,
              children: [
                const PpForgeIcon(
                  PpForgeIcons.wallet,
                  size: PpForgeIconSize.lg,
                ),
                PpForgeIcon(
                  PpForgeIcons.wallet,
                  size: PpForgeIconSize.lg,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
          HubUse(
            label: 'PpForgeIcon — error, small',
            page: 'Validation, overdue rows',
            child: left(
              PpForgeIcon(
                PpForgeIcons.wallet,
                size: PpForgeIconSize.sm,
                color: scheme.error,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: PpForgeSpacing.xl),
      HubPlayground(
        title: 'PpForgeSwitch',
        note: 'The one on / off switch. enabled off = onChanged null (greyed).',
        controls: const [
          PlayBool('value', initialValue: true),
          PlayBool('enabled', initialValue: true),
        ],
        builder: (context, v) => HubStateful<bool?>(
          // Re-keyed by the control so the switch follows the control.
          key: ValueKey(v<bool>('value')),
          initial: v<bool>('value'),
          builder: (context, on, set) => left(
            PpForgeSwitch(
              value: on ?? false,
              semanticLabel: 'demo switch',
              onChanged: v<bool>('enabled') ? (x) => set(x) : null,
            ),
          ),
        ),
      ),
      HubPlayground(
        title: 'SelectCheck',
        note:
            'Rounded-square multi-select mark. value true = ✓, false = empty, '
            'null = partial (select all only).',
        controls: [
          PlayChoice<bool?>('value', const [
            ('on', true),
            ('off', false),
            ('partial', null),
          ]),
          const PlayNum('size', min: 16, max: 40, step: 4, initialValue: 20),
        ],
        builder: (context, v) => left(
          SelectCheck(
            value: v<bool?>('value'),
            size: v<double>('size'),
            onTap: () {},
          ),
        ),
      ),
      HubPlayground(
        title: 'SelectAllCount',
        note:
            'The "n/N" select-all control: none = empty, all = ✓, between = '
            'partial; total 0 disables it.',
        controls: const [
          PlayNum('selected', min: 0, max: 8, step: 1, initialValue: 2),
          PlayNum('total', min: 0, max: 8, step: 1, initialValue: 5),
        ],
        builder: (context, v) => left(
          SelectAllCount(
            selected: v<double>('selected').round(),
            total: v<double>('total').round(),
            onTap: () {},
          ),
        ),
      ),
      HubPlayground(
        title: 'PpForgeDivider',
        note:
            'One hairline. height sets the space it takes; indent insets both '
            'ends (PpForgeDivider.row() = indent of a detail row).',
        controls: const [
          PlayNum('height', min: 1, max: 48, step: 1, initialValue: 1),
          PlayNum('indent', min: 0, max: 48, step: 4, initialValue: 0),
        ],
        builder: (context, v) => PpForgeDivider(
          height: v<double>('height'),
          indent: v<double>('indent'),
        ),
      ),
      HubPlayground(
        title: 'AddTile',
        note:
            'The dashed "add" slot. circleSize applies to the circle variant; '
            'enabled off = onTap null.',
        controls: [
          PlayChoice<AddTileVariant>('variant', [
            for (final x in AddTileVariant.values) (x.name, x),
          ]),
          const PlayText('label', initialValue: 'Add new'),
          const PlayNum(
            'circleSize',
            min: 32,
            max: 72,
            step: 8,
            initialValue: 48,
          ),
          const PlayBool('enabled', initialValue: true),
        ],
        builder: (context, v) {
          final variant = v<AddTileVariant>('variant');
          final tile = AddTile(
            label: v<String>('label'),
            variant: variant,
            circleSize: v<double>('circleSize'),
            onTap: v<bool>('enabled') ? () {} : null,
          );
          return variant == AddTileVariant.circle ? left(tile) : tile;
        },
      ),
      HubPlayground(
        title: 'PpForgeSpinner',
        note:
            'A call in flight (save, delete). value null = spinning; a number '
            '= determinate. Skeletons are for the first load only.',
        controls: [
          PlayChoice<PpForgeSpinnerSize>('size', [
            for (final s in PpForgeSpinnerSize.values) (s.name, s),
          ]),
          PlayChoice<Color?>('color', [
            ('default', null),
            ('tertiary', scheme.tertiary),
            ('error', scheme.error),
          ]),
          PlayChoice<double?>('value', const [
            ('spinning', null),
            ('25%', 0.25),
            ('75%', 0.75),
          ]),
        ],
        builder: (context, v) => left(
          PpForgeSpinner(
            size: v<PpForgeSpinnerSize>('size'),
            color: v<Color?>('color'),
            value: v<double?>('value'),
          ),
        ),
      ),
      HubPlayground(
        title: 'Skeletons',
        note:
            'Placeholders for the first load. SkeletonListTile: avatarSize, '
            'lines, indent. SkeletonBox: height, borderRadius, shape.',
        controls: [
          const PlayNum(
            'avatarSize',
            min: 24,
            max: 56,
            step: 8,
            initialValue: 40,
          ),
          const PlayNum('lines', min: 1, max: 2, step: 1, initialValue: 2),
          const PlayNum('indent', min: 0, max: 32, step: 8, initialValue: 0),
          const PlayNum(
            'boxHeight',
            min: 16,
            max: 96,
            step: 8,
            initialValue: 64,
          ),
          PlayChoice<BoxShape>('boxShape', [
            for (final s in BoxShape.values) (s.name, s),
          ]),
        ],
        builder: (context, v) {
          final circle = v<BoxShape>('boxShape') == BoxShape.circle;
          final h = v<double>('boxHeight');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonListTile(
                avatarSize: v<double>('avatarSize'),
                lines: v<double>('lines').round(),
                indent: v<double>('indent'),
              ),
              const SizedBox(height: PpForgeSpacing.sm),
              left(
                SkeletonBox(
                  width: circle ? h : null,
                  height: h,
                  borderRadius: PpForgeRadius.lg,
                  shape: v<BoxShape>('boxShape'),
                ),
              ),
            ],
          );
        },
      ),
      HubPlayground(
        title: 'PpForgeIcon',
        note:
            'One icon: a glyph at an PpForgeIconSize step (null = inherit the '
            'surrounding IconTheme), in color or the surrounding icon colour.',
        controls: [
          PlayChoice<double?>('size', const [
            ('inherit', null),
            ('xs', PpForgeIconSize.xs),
            ('sm', PpForgeIconSize.sm),
            ('md', PpForgeIconSize.md),
            ('lg', PpForgeIconSize.lg),
            ('xl', PpForgeIconSize.xl),
            ('hero', PpForgeIconSize.hero),
          ]),
          PlayChoice<Color?>('color', [
            ('inherit', null),
            ('primary', scheme.primary),
            ('error', scheme.error),
          ]),
        ],
        builder: (context, v) => left(
          PpForgeIcon(
            PpForgeIcons.wallet,
            size: v<double?>('size'),
            color: v<Color?>('color'),
          ),
        ),
      ),
    ],
  );
}

TextStyle? _bodyLarge(TextTheme t) => t.bodyLarge;
