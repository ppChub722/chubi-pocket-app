import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';
import 'atoms_badge_avatar_page.dart' show hubHardAvatarCases;

/// `/dev/atoms/button` — buttons, icon buttons, bulk delete.
Widget buildButtonPage(BuildContext context) => const _ButtonPage();

class _ButtonPage extends StatefulWidget {
  const _ButtonPage();

  @override
  State<_ButtonPage> createState() => _ButtonPageState();
}

class _ButtonPageState extends State<_ButtonPage> {
  bool _loading = false;
  IconChipActivity _activity = IconChipActivity.none;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HubSubheading(
          'In the app',
          note: 'The real presets and where they are used.',
        ),
        HubDemo(
          title: 'AppButton — variants',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final v in AppButtonVariant.values)
                AppButton(label: v.name, variant: v, onPressed: () {}),
            ],
          ),
        ),
        HubDemo(
          title: 'States',
          note:
              'Disabled (onPressed null) and loading (spinner replaces the label).',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              const AppButton(label: 'Disabled', onPressed: null),
              AppButton(label: 'Loading', loading: true, onPressed: () {}),
              AppButton(
                label: 'With icon',
                icon: AppIcons.add,
                onPressed: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'submits — offline',
          note:
              'A button that sends to the server (save, submit, sign in, '
              'delete) passes submits: true and disables itself while the '
              'app is offline (ConnectionScope). Other buttons stay live. '
              'Shown here inside an offline scope.',
          child: ConnectionScope(
            offline: true,
            reconnects: 0,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(label: 'Save', submits: true, onPressed: () {}),
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outlined,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'Large, full width',
          child: AppButton(
            label: _loading ? 'Saving…' : 'Tap to fake a save',
            size: AppButtonSize.large,
            expand: true,
            loading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              await Future<void>.delayed(const Duration(seconds: 2));
              if (mounted) setState(() => _loading = false);
            },
          ),
        ),
        HubDemo(
          title: 'AppIconButton — activity',
          note:
              'none | progress (a bar overlaid under the icon) | done (the icon '
              'at ~0.3 with a ✓ on top). The icon and the button size never move. '
              'Tap to cycle; the count badge (3) floats outside the circle, '
              'top-right, and hides while a job runs.',
          child: AppIconButton(
            icon: AppIcons.notifications,
            badgeCount: 3,
            tooltip: 'Cycle',
            activity: _activity,
            onPressed: () => setState(
              () => _activity =
                  IconChipActivity.values[(_activity.index + 1) %
                      IconChipActivity.values.length],
            ),
          ),
        ),
        HubDemo(
          title: 'Edit ✏️ — AppIconButton.edit',
          note:
              "The round ✏️. Hero top row (32, level with the chips: AppHeroCard, "
              "the transaction hero, the wallet hero) and a list header's "
              "\"enter edit / reorder mode\" (36: wallets, categories, tags). "
              "Null onPressed dims it.",
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              HubCell(
                caption: 'hero 32',
                child: AppIconButton.edit(tooltip: 'Edit', onPressed: () {}),
              ),
              HubCell(
                caption: 'list 36',
                child: AppIconButton.edit(tooltip: 'Edit', onPressed: () {}),
              ),
              const HubCell(
                caption: 'disabled',
                child: AppIconButton.edit(onPressed: null),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Edit-mode bar — Cancel | Save',
          note:
              'The two big buttons of the bottom bar in edit / reorder mode or '
              'a form (ModeActionBar, Molecules → Bars, adds Undo): an '
              'outlined Cancel and a filled Save, Save disabled until there '
              'is something to save, a spinner while saving. Used by every '
              'edit / reorder page and the create forms.',
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Save',
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Shell top-right buttons',
          note:
              "The top bar's chips, normal and \"current page\" (the page they "
              "open is on screen: primary-container fill + primary ring). "
              "Inbox ⏳ (pending drafts) and bell carry a count badge that floats outside the circle, top-right, in a page-colour ring; the "
              "profile chip is an AppAvatarButton whose ring follows the "
              "avatar's own shape. Used by AppTopBar.",
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              HubCell(
                caption: 'inbox | normal',
                child: AppIconButton(
                  icon: AppIcons.pending,
                  badgeCount: 3,
                  tooltip: 'Pending',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'inbox | current',
                child: AppIconButton(
                  icon: AppIcons.pending,
                  badgeCount: 3,
                  selected: true,
                  tooltip: 'Pending',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'bell | normal',
                child: AppIconButton(
                  icon: AppIcons.notifications,
                  badgeCount: 12,
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'bell | current',
                child: AppIconButton(
                  icon: AppIcons.notifications,
                  selected: true,
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'profile | normal',
                child: AppAvatarButton(
                  tooltip: 'Profile',
                  onTap: () {},
                  child: const UserAvatar(displayName: 'Aom Chan', size: 32),
                ),
              ),
              HubCell(
                caption: 'profile | current',
                child: AppAvatarButton(
                  tooltip: 'Profile',
                  active: true,
                  onTap: () {},
                  child: const UserAvatar(displayName: 'Aom Chan', size: 32),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Profile chip — hard-case Icon Maker avatars',
          note:
              'The top bar\'s profile chip with the avatars that stress it: '
              'thick / thin frames, ring only, glyph only, every shape (the ring, '
              'shadow and ripple follow the avatar\'s own shape), gradients, '
              'low contrast. Each normal and "current page". Built exactly like '
              'the top bar builds it: the avatar at 32 inside the 40 frame, the '
              'icon-maker frame dropped (the chip\'s ring says active / not). '
              'The same set as Atoms → Badge & avatar.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (name, code) in hubHardAvatarCases)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      for (final active in [false, true]) ...[
                        const SizedBox(width: AppSpacing.md),
                        _profileChip(code, active: active),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'CountBadge — the one count badge',
          note:
              'A red pill with a page-colour ring: "99+" past 99, hidden at 0. '
              'It floats off the top-right of what it counts, half outside, '
              'anchored to that thing (CountBadge.floating) — an icon button '
              "or a tab's label, never over the icon or text. Used by "
              'AppIconButton (shell inbox / bell) and AppTabBar.',
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final n in [0, 1, 12, 99, 120])
                HubCell(
                  caption: n == 0 ? '0 (hidden)' : '$n',
                  child: CountBadge(count: n),
                ),
              HubCell(
                caption: 'on a button',
                child: AppIconButton(
                  icon: AppIcons.notifications,
                  badgeCount: 7,
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'on a tab label',
                child: CountBadge.floating(
                  count: 12,
                  offset: const Offset(-14, -10),
                  child: Text(
                    'Pending',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Flat icon buttons — close | clear | more | back | flat',
          note:
              'No chip: a plain 48 dp tap target. ✕ close (PickerSheet, '
              'SideSheet, the quick-create header, update banner, chat dial); '
              '✕ clear (remove a split / event / row, AppMessage); ⋯ more '
              '(a member row); ← back; .flat for anything else (the 🗑 in a '
              'draft header). iconSize / color override the look; dense '
              'shrinks the target for inline use.',
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              HubCell(
                caption: 'close',
                child: AppIconButton.close(tooltip: 'Close', onPressed: () {}),
              ),
              HubCell(
                caption: 'clear',
                child: AppIconButton.clear(tooltip: 'Clear', onPressed: () {}),
              ),
              HubCell(
                caption: 'more',
                child: AppIconButton.more(tooltip: 'More', onPressed: () {}),
              ),
              HubCell(
                caption: 'back',
                child: AppIconButton.back(tooltip: 'Back', onPressed: () {}),
              ),
              HubCell(
                caption: 'flat 🗑 (error)',
                child: AppIconButton.flat(
                  icon: AppIcons.delete,
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Delete',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'dense, 18',
                child: AppIconButton.clear(
                  dense: true,
                  iconSize: 18,
                  onPressed: () {},
                ),
              ),
              const HubCell(
                caption: 'disabled',
                child: AppIconButton.close(onPressed: null),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'BulkDeleteButton',
          note: 'A red trash icon, no label — select toolbars.',
          child: BulkDeleteButton(tooltip: 'Delete', onPressed: () {}),
        ),

        HubPlayground(
          title: 'AppButton',
          hug: Alignment.centerLeft,
          note: 'Every option AppButton has.',
          controls: [
            const PlayText('label', initialValue: 'Save'),
            PlayChoice<AppButtonVariant>('variant', [
              for (final v in AppButtonVariant.values) (v.name, v),
            ]),
            PlayChoice<AppButtonSize>('size', [
              for (final v in AppButtonSize.values) (v.name, v),
            ]),
            const PlayBool('icon'),
            const PlayBool('loading'),
            const PlayBool('expand'),
            const PlayBool('enabled', initialValue: true),
          ],
          builder: (context, v) => AppButton(
            label: v<String>('label'),
            variant: v<AppButtonVariant>('variant'),
            size: v<AppButtonSize>('size'),
            icon: v<bool>('icon') ? AppIcons.check : null,
            loading: v<bool>('loading'),
            expand: v<bool>('expand'),
            onPressed: v<bool>('enabled') ? () {} : null,
          ),
        ),
        HubPlayground(
          title: 'AppIconButton',
          hug: Alignment.centerLeft,
          note: 'The chip itself (the flat variants are in the demos below).',
          controls: [
            PlayChoice<IconData>('icon', [
              ('edit', AppIcons.edit),
              ('close', AppIcons.close),
              ('inbox', AppIcons.pending),
              ('bell', AppIcons.notifications),
              ('delete', AppIcons.delete),
            ]),
            const PlayNum(
              'badgeCount',
              min: 0,
              max: 120,
              step: 1,
              initialValue: 0,
            ),
            const PlayBool('selected'),
            const PlayBool('destructive'),
            const PlayNum('size', min: 32, max: 48, step: 4, initialValue: 40),
            PlayChoice<IconChipActivity>('activity', [
              for (final a in IconChipActivity.values) (a.name, a),
            ]),
            const PlayBool('enabled', initialValue: true),
          ],
          builder: (context, v) => AppIconButton(
            icon: v<IconData>('icon'),
            badgeCount: v<double>('badgeCount').round(),
            selected: v<bool>('selected'),
            destructive: v<bool>('destructive'),
            size: v<double>('size'),
            activity: v<IconChipActivity>('activity'),
            tooltip: 'Icon button',
            onPressed: v<bool>('enabled') ? () {} : null,
          ),
        ),
      ],
    );
  }
}

/// The top bar's profile chip for [code]: the avatar at 32 in the 40 frame,
/// the ring following the avatar's shape, the icon-maker frame dropped.
Widget _profileChip(IconCode code, {required bool active}) {
  final outline = IconShape.fromId(code.shape).radius(40);
  return AppAvatarButton(
    outline: outline,
    active: active,
    tooltip: 'Profile',
    onTap: () {},
    child: UserAvatar(
      displayName: 'Bee',
      iconCode: IconCode(
        icon: code.icon,
        iconColors: code.iconColors,
        background: code.background,
        bgColors: code.bgColors,
        shape: code.shape,
      ),
      size: 32,
    ),
  );
}
