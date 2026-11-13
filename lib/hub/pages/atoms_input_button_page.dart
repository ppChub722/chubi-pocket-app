import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'package:pp_forge_core/hub.dart';
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
          title: 'Chip-sized buttons and a trailing icon',
          note:
              'size: mini / chip / control match ChipSize (height, padding, icon, '
              'label). trailingIcon puts ▾ after the label (settings dropdown rows).',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final s in const [
                PpForgeButtonSize.mini,
                PpForgeButtonSize.chip,
                PpForgeButtonSize.control,
              ])
                PpForgeButton(
                  label: s.name,
                  variant: PpForgeButtonVariant.outlined,
                  size: s,
                  onPressed: () {},
                ),
              PpForgeButton(
                label: '80%',
                variant: PpForgeButtonVariant.outlined,
                size: PpForgeButtonSize.control,
                trailingIcon: AppIcons.dropdown,
                onPressed: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'PpForgeButton — variants',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              for (final v in PpForgeButtonVariant.values)
                PpForgeButton(label: v.name, variant: v, onPressed: () {}),
            ],
          ),
        ),
        HubDemo(
          title: 'States',
          note:
              'Disabled (onPressed null) and loading (spinner replaces the label).',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              const PpForgeButton(label: 'Disabled', onPressed: null),
              PpForgeButton(label: 'Loading', loading: true, onPressed: () {}),
              PpForgeButton(
                label: 'With icon',
                icon: AppIcons.add,
                onPressed: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'kind — icon by role',
          note:
              'PpForgeButton(kind:) takes its icon from ButtonIconKind, one table '
              'for the whole app (Save, Cancel, Clear, ...). An explicit icon: '
              'wins. viewAll puts its icon after the label. Not set = no icon.',
          child: Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              for (final k in ButtonIconKind.values)
                PpForgeButton(
                  label: k.name,
                  kind: k,
                  variant: PpForgeButtonVariant.outlined,
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
              'Also gated: OccurrenceAction (submits by default), SheetOption '
              '(submits: true), SettingDropdownRow / SettingMenuRow (submits '
              'by default; false for a local or edit-mode value). Shown here '
              'inside an offline scope.',
          child: ConnectionScope(
            offline: true,
            reconnects: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: PpForgeSpacing.sm,
                  runSpacing: PpForgeSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PpForgeButton(label: 'Save', submits: true, onPressed: () {}),
                    PpForgeButton(
                      label: 'Cancel',
                      variant: PpForgeButtonVariant.outlined,
                      onPressed: () {},
                    ),
                    OccurrenceActions(
                      primary: OccurrenceAction(label: 'ยืนยัน', onTap: () {}),
                      more: [OccurrenceAction(label: 'ข้าม', onTap: () {})],
                    ),
                  ],
                ),
                SettingDropdownRow<int>(
                  label: 'สกุลเงิน',
                  value: 'THB',
                  selected: 0,
                  onSelected: (_) {},
                  options: const [SheetOption(value: 0, label: 'THB')],
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'Large, full width',
          child: PpForgeButton(
            label: _loading ? 'Saving…' : 'Tap to fake a save',
            size: PpForgeButtonSize.large,
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
          title: 'PpForgeIconButton — activity',
          note:
              'none | progress (a bar overlaid under the icon) | done (the icon '
              'at ~0.3 with a ✓ on top). The icon and the button size never move. '
              'Tap to cycle; the count badge (3) floats outside the circle, '
              'top-right, and hides while a job runs.',
          child: PpForgeIconButton(
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
          title: 'Edit ✏️ — PpForgeIconButton.edit',
          note:
              "The round ✏️. Hero top row (32, level with the chips: PpForgeHeroCard, "
              "the transaction hero, the wallet hero) and a list header's "
              "\"enter edit / reorder mode\" (36: wallets, categories, tags). "
              "Null onPressed dims it.",
          child: Wrap(
            spacing: PpForgeSpacing.lg,
            runSpacing: PpForgeSpacing.sm,
            children: [
              HubCell(
                caption: 'hero 32',
                child: PpForgeIconButton.edit(tooltip: 'Edit', onPressed: () {}),
              ),
              HubCell(
                caption: 'list 36',
                child: PpForgeIconButton.edit(tooltip: 'Edit', onPressed: () {}),
              ),
              const HubCell(
                caption: 'disabled',
                child: PpForgeIconButton.edit(onPressed: null),
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
                child: PpForgeButton(
                  label: 'Cancel',
                  variant: PpForgeButtonVariant.outlined,
                  size: PpForgeButtonSize.large,
                  expand: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: PpForgeSpacing.sm),
              Expanded(
                child: PpForgeButton(
                  label: 'Save',
                  size: PpForgeButtonSize.large,
                  expand: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'PpForgeIconButton.filled',
          note:
              'Primary fill, icon in onPrimary: the ✓ at the end of a list '
              'row (ListRowAction.button). Null onPressed = disabled.',
          child: Wrap(
            spacing: PpForgeSpacing.lg,
            runSpacing: PpForgeSpacing.md,
            children: [
              HubCell(
                caption: 'chip size',
                child: PpForgeIconButton.filled(
                  icon: AppIcons.check,
                  tooltip: 'ยืนยัน',
                  size: ChipSize.chip.heightOf(context),
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'control size',
                child: PpForgeIconButton.filled(
                  icon: AppIcons.check,
                  tooltip: 'ยืนยัน',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'disabled',
                child: PpForgeIconButton.filled(
                  icon: AppIcons.check,
                  size: ChipSize.chip.heightOf(context),
                  onPressed: null,
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
              "profile chip is an PpForgeAvatarButton whose ring follows the "
              "avatar's own shape. Used by AppTopBar.",
          child: Wrap(
            spacing: PpForgeSpacing.lg,
            runSpacing: PpForgeSpacing.md,
            children: [
              HubCell(
                caption: 'inbox | normal',
                child: PpForgeIconButton(
                  icon: AppIcons.pending,
                  badgeCount: 3,
                  tooltip: 'Pending',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'inbox | current',
                child: PpForgeIconButton(
                  icon: AppIcons.pending,
                  badgeCount: 3,
                  selected: true,
                  tooltip: 'Pending',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'bell | normal',
                child: PpForgeIconButton(
                  icon: AppIcons.notifications,
                  badgeCount: 12,
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'bell | current',
                child: PpForgeIconButton(
                  icon: AppIcons.notifications,
                  selected: true,
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'profile | normal',
                child: PpForgeAvatarButton(
                  tooltip: 'Profile',
                  onTap: () {},
                  child: Avatar(AvatarData.forName('Aom Chan'), size: 32),
                ),
              ),
              HubCell(
                caption: 'profile | current',
                child: PpForgeAvatarButton(
                  tooltip: 'Profile',
                  active: true,
                  onTap: () {},
                  child: Avatar(AvatarData.forName('Aom Chan'), size: 32),
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'MirrorSurface — any shape',
          note:
              'The app\'s one glass (PpForgeGlass.standard = soft, Samsung style: '
              'blur, livelier colours, milky tint, top light, thin border, '
              'outside shadow; PpForgeGlass.liquid = the Apple-style lens shader) '
              'on any ShapeBorder. The top bar\'s pill and chips (via '
              'MirrorScope) and the bottom bar use it; the profile chip stays '
              'solid. Shown over stripes, since glass needs something behind '
              'it.',
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE53935),
                  Color(0xFFFFB300),
                  Color(0xFF43A047),
                  Color(0xFF1E88E5),
                  Color(0xFF8E24AA),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(PpForgeSpacing.lg),
              child: Wrap(
                spacing: PpForgeSpacing.lg,
                runSpacing: PpForgeSpacing.md,
                children: [
                  for (final (caption, shape, w, h)
                      in <(String, ShapeBorder, double, double)>[
                        ('circle', const CircleBorder(), 40, 40),
                        ('stadium', const StadiumBorder(), 120, 40),
                        (
                          'rounded 22',
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          120,
                          44,
                        ),
                        for (final s in PpForgeIconShape.values)
                          (
                            s.name,
                            RoundedRectangleBorder(borderRadius: s.radius(48)),
                            48,
                            48,
                          ),
                      ])
                    HubCell(
                      caption: caption,
                      child: MirrorSurface(
                        shape: shape,
                        child: SizedBox(width: w, height: h),
                      ),
                    ),
                  HubCell(
                    caption: 'selected',
                    child: MirrorScope(
                      child: PpForgeIconButton(
                        icon: AppIcons.notifications,
                        selected: true,
                        onPressed: () {},
                      ),
                    ),
                  ),
                  HubCell(
                    caption: 'chip',
                    child: MirrorScope(
                      child: PpForgeIconButton(
                        icon: AppIcons.pending,
                        badgeCount: 3,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  padding: const EdgeInsets.only(bottom: PpForgeSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      for (final active in [false, true]) ...[
                        const SizedBox(width: PpForgeSpacing.md),
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
              'PpForgeIconButton (shell inbox / bell) and PpForgeTabBar.',
          child: Wrap(
            spacing: PpForgeSpacing.xl,
            runSpacing: PpForgeSpacing.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final n in [0, 1, 12, 99, 120])
                HubCell(
                  caption: n == 0 ? '0 (hidden)' : '$n',
                  child: CountBadge(count: n),
                ),
              HubCell(
                caption: 'on a button',
                child: PpForgeIconButton(
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
              '✕ clear (remove a split / event / row, PpForgeMessage); ⋯ more '
              '(a member row); ← back; .flat for anything else (the 🗑 in a '
              'draft header). iconSize / color override the look; dense '
              'shrinks the target for inline use.',
          child: Wrap(
            spacing: PpForgeSpacing.lg,
            runSpacing: PpForgeSpacing.sm,
            children: [
              HubCell(
                caption: 'close',
                child: PpForgeIconButton.close(tooltip: 'Close', onPressed: () {}),
              ),
              HubCell(
                caption: 'clear',
                child: PpForgeIconButton.clear(tooltip: 'Clear', onPressed: () {}),
              ),
              HubCell(
                caption: 'more',
                child: PpForgeIconButton.more(tooltip: 'More', onPressed: () {}),
              ),
              HubCell(
                caption: 'back',
                child: PpForgeIconButton.back(tooltip: 'Back', onPressed: () {}),
              ),
              HubCell(
                caption: 'flat 🗑 (error)',
                child: PpForgeIconButton.flat(
                  icon: AppIcons.delete,
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Delete',
                  onPressed: () {},
                ),
              ),
              HubCell(
                caption: 'dense, 18',
                child: PpForgeIconButton.clear(
                  dense: true,
                  iconSize: 18,
                  onPressed: () {},
                ),
              ),
              const HubCell(
                caption: 'disabled',
                child: PpForgeIconButton.close(onPressed: null),
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
          title: 'PpForgeButton',
          hug: Alignment.centerLeft,
          note: 'Every option PpForgeButton has.',
          controls: [
            const PlayText('label', initialValue: 'Save'),
            PlayChoice<PpForgeButtonVariant>('variant', [
              for (final v in PpForgeButtonVariant.values) (v.name, v),
            ]),
            PlayChoice<PpForgeButtonSize>('size', [
              for (final v in PpForgeButtonSize.values) (v.name, v),
            ]),
            const PlayBool('icon'),
            const PlayBool('loading'),
            const PlayBool('expand'),
            const PlayBool('enabled', initialValue: true),
          ],
          builder: (context, v) => PpForgeButton(
            label: v<String>('label'),
            variant: v<PpForgeButtonVariant>('variant'),
            size: v<PpForgeButtonSize>('size'),
            icon: v<bool>('icon') ? AppIcons.check : null,
            loading: v<bool>('loading'),
            expand: v<bool>('expand'),
            onPressed: v<bool>('enabled') ? () {} : null,
          ),
        ),
        HubPlayground(
          title: 'PpForgeIconButton',
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
          builder: (context, v) => PpForgeIconButton(
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
Widget _profileChip(PpForgeIconCode code, {required bool active}) {
  final outline = PpForgeIconShape.fromId(code.shape).radius(40);
  return PpForgeAvatarButton(
    outline: outline,
    active: active,
    tooltip: 'Profile',
    onTap: () {},
    child: Avatar(
      AvatarData.forName(
        'Bee',
        iconCode: PpForgeIconCode(
          icon: code.icon,
          iconColors: code.iconColors,
          background: code.background,
          bgColors: code.bgColors,
          shape: code.shape,
        ),
      ),
      size: 32,
    ),
  );
}
