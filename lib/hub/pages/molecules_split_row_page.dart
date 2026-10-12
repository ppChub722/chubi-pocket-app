import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/ui/molecules/split-row` — one row of a bill split: avatar | name |
/// amount | a fixed trailing slot.
Widget buildSplitRowPage(BuildContext context) => const _SplitRowPage();

class _SplitRowPage extends StatefulWidget {
  const _SplitRowPage();

  @override
  State<_SplitRowPage> createState() => _SplitRowPageState();
}

class _SplitRowPageState extends State<_SplitRowPage> {
  bool _auto = true;
  final _typed = TextEditingController(text: 'Mali');
  final _typedFocus = FocusNode();

  @override
  void dispose() {
    _typed.dispose();
    _typedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubPlayground(
          title: 'SplitRow',
          note:
              'The name cell by who it is, the avatar level, the trailing '
              'action.',
          controls: [
            PlayChoice<int>('name', [
              ('my share', 0),
              ('typed', 1),
              ('contact', 2),
              ('linked', 3),
            ]),
            const PlayBool('autoOn'),
            PlayChoice<int>('trailing', [('action', 0), ('none', 1)]),
          ],
          builder: (context, v) {
            final kind = v<int>('name');
            final trailing = v<int>('trailing') == 1
                ? null
                : kind == 0
                ? SplitRowAction(
                    icon: AppIcons.auto,
                    tooltip: 'Auto',
                    selected: v<bool>('autoOn'),
                    onTap: () {},
                  )
                : SplitRowAction(
                    icon: AppIcons.close,
                    tooltip: 'Remove',
                    onTap: () {},
                  );
            final avatar = kind == 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppAvatar(name: 'Me', size: SplitRow.avatarSize),
                      SizedBox(
                        width: PersonMark.linkSlotWidth(SplitRow.avatarSize),
                      ),
                    ],
                  )
                : PersonMark(
                    name: 'Mali',
                    level: switch (kind) {
                      1 => PersonLevel.name,
                      2 => PersonLevel.contact,
                      _ => PersonLevel.linked,
                    },
                    size: SplitRow.avatarSize,
                    reserveLinkSlot: kind != 3,
                  );
            return HubWithController(
              initial: 'Mali',
              builder: (context, c) => SplitRow(
                avatar: avatar,
                name: switch (kind) {
                  0 => const SplitRowName.muted('My share'),
                  1 => SplitRowName.input(
                    controller: c,
                    focusNode: _typedFocus,
                    hint: 'Name',
                  ),
                  _ => const SplitRowName.picked('Mali'),
                },
                amount: const _DemoAmount('฿150.00'),
                trailing: trailing,
              ),
            );
          },
        ),
        const HubSubheading(
          'In the app',
          note: 'Every level side by side, as the split editor shows them.',
        ),
        HubDemo(
          title: 'SplitRow + SplitRowAction + SplitRowName',
          note:
              'One row of a bill split: avatar | name | amount | a fixed 40px '
              'trailing slot, the same on every row so amounts and icons line '
              'up. Every name starts at the same x and is in the normal weight. '
              'Me: italic + muted (the Thai font has no true italic, so it is '
              'slanted synthetically), with the auto switch (tinted circle when '
              'on). Level 1, a typed name: an outlined input. Level 2, a '
              'contact: the name on a faint highlight in the avatar colour. '
              'Level 3, a linked contact: the same plus the 🔗 mark. Tap the '
              'highlighted name = the picker. ✕ is the plain icon.',
          child: Column(
            children: [
              SplitRow(
                avatar: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppAvatar(name: 'Me', size: SplitRow.avatarSize),
                    SizedBox(
                      width: PersonMark.linkSlotWidth(SplitRow.avatarSize),
                    ),
                  ],
                ),
                name: const SplitRowName.muted('My share'),
                amount: const _DemoAmount('฿400.00'),
                trailing: SplitRowAction(
                  icon: AppIcons.auto,
                  tooltip: 'Auto',
                  selected: _auto,
                  onTap: () => setState(() => _auto = !_auto),
                ),
              ),
              SplitRow(
                avatar: const PersonMark(
                  name: 'Mali',
                  level: PersonLevel.name,
                  size: SplitRow.avatarSize,
                  reserveLinkSlot: true,
                ),
                name: SplitRowName.input(
                  controller: _typed,
                  focusNode: _typedFocus,
                  hint: 'Name',
                ),
                amount: const _DemoAmount('฿150.00'),
                trailing: SplitRowAction(
                  icon: AppIcons.close,
                  tooltip: 'Remove',
                  onTap: _noop,
                ),
              ),
              SplitRow(
                avatar: const PersonMark(
                  name: 'Bee',
                  level: PersonLevel.contact,
                  size: SplitRow.avatarSize,
                  reserveLinkSlot: true,
                ),
                name: const SplitRowName.picked('Bee', onTap: _noop),
                amount: const _DemoAmount('฿150.00'),
                trailing: SplitRowAction(
                  icon: AppIcons.close,
                  tooltip: 'Remove',
                  onTap: _noop,
                ),
              ),
              SplitRow(
                avatar: const PersonMark(
                  name: 'Ton',
                  level: PersonLevel.linked,
                  size: SplitRow.avatarSize,
                ),
                name: const SplitRowName.picked('Ton', onTap: _noop),
                amount: const _DemoAmount('฿150.00'),
                trailing: SplitRowAction(
                  icon: AppIcons.close,
                  tooltip: 'Remove',
                  onTap: _noop,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _noop() {}

/// The amount cell stand-in (the real one is the split section's input).
class _DemoAmount extends StatelessWidget {
  const _DemoAmount(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 104,
    height: SplitRow.height,
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
}
